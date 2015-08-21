# This file is part of Joomla VS.

# Joomla VS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Joomla VS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Joomla VS.  If not, see <http://www.gnu.org/licenses/>.

require 'slop'

require_relative 'lib/output'
require_relative 'lib/component_scanner'
require_relative 'lib/module_scanner'
require_relative 'lib/fingerprint_scanner'
require_relative 'lib/template_scanner'

class JoomlaVS
  include Output

  attr_accessor :opts

  def initialize
    initialize_options
  end

  def initialize_options
    @opts = Slop.parse do |o|
      o.separator 'Basic options'
      o.string '-u', '--url', 'The Joomla URL/domain to scan.'
      o.string '--basic-auth', '<username:password> The basic HTTP authentication credentials'
      o.bool '-v', '--verbose', 'Enable verbose mode'

      o.separator 'Enumeration options'
      o.bool '-a', '--scan-all', 'Scan for all vulnerable extensions'
      o.bool '-c', '--scan-components', 'Scan for vulnerable components'
      o.bool '-m', '--scan-modules', 'Scan for vulnerable modules'
      o.bool '-t', '--scan-templates', 'Scan for vulnerable templates'
      o.bool '-q', '--quiet', 'Scan using only passive methods'

      o.separator 'Advanced options'
      o.bool '--follow-redirection', 'Automatically follow redirections'
      o.bool '--no-colour', 'Disable colours in output'
      o.string '--proxy', '<[protocol://]host:port> HTTP, SOCKS4 SOCKS4A and SOCKS5 are supported. If no protocol is given, HTTP will be used'
      o.string '--proxy-auth', '<username:password> The proxy authentication credentials'
      o.integer '--threads', 'The number of threads to use when multi-threading requests', default: 20
      o.string '--user-agent', 'The user agent string to send with all requests', default: 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0'
    end
  end

  def display_reference(ref, base_url)
    return unless ref
    if ref.is_a?(Array)
      ref.each do |id|
        print_indent("Reference: #{base_url}#{id}/")
      end
    else
      print_indent("Reference: #{base_url}#{ref}/")
    end
  end

  def display_vulns(vulns)
    vulns.each do |v|
      print_line_break
      print_error("Title: #{v['title']}")
      display_reference v['edbid'], 'https://www.exploit-db.com/exploits/'
      display_reference v['cveid'], 'http://www.cvedetails.com/cve/'
      display_reference v['osvdbid'], 'http://osvdb.org/'
      print_info("Fixed in: #{v['fixed_in']}") if v['fixed_in']
      print_line_break
    end
  end

  def display_detected_extension(e)
    print_line_break
    print_good("Name: #{e[:name]} - v#{e[:version]}")
    print_indent("Location: #{e[:extension_url]}")
    print_indent("Manifest: #{e[:manifest_url]}")
    print_indent("Description: #{e[:description]}") unless e[:description].empty?
    print_indent("Author: #{e[:author]}") unless e[:author].empty?
    print_indent("Author URL: #{e[:author_url]}") unless e[:author_url].empty?

    display_vulns(e[:vulns])

    print_horizontal_rule
  end

  def joomla_vulnerabilities(version)
    json = File.read('data/joomla.json')
    vulns = JSON.parse(json)
    found = []

    vulns.each do |v|
      found.push(v) if ExtensionScanner.version_is_vulnerable(version, v)
    end

    found
  end

  def check_target_redirection(scanner)
    redirected_uri = scanner.target_redirects_to
    return unless redirected_uri

    if opts[:follow_redirection]
      scanner.update_target_uri redirected_uri
      print_info("Now targetting #{scanner.target_uri}") if opts[:verbose]
    else
      print_line_break
      print_info("The remote host tried to redirect to: #{redirected_uri}")
      answer = read_input('Do you want to follow the redirection? [Y]es [N]o [A]bort: ')
      if answer =~ /^y/i
        scanner.update_target_uri redirected_uri
        print_info("Now targetting #{scanner.target_uri}") if opts[:verbose]
      elsif answer =~ /^a/i
        print_line_break
        print_good('Scan aborted')
        exit(1)
      end
    end
  end

  def components_filter(scanner, use_index, use_admin_index)
    components = scanner.extract_components_from_home
    components = components | scanner.extract_components_from_index if use_index
    components = components | scanner.extract_components_from_admin_index if use_admin_index
    components
  end

  def modules_filter(scanner, use_index, use_admin_index)
    modules = scanner.extract_modules_from_home
    modules = modules | scanner.extract_modules_from_index if use_index
    modules = modules | scanner.extract_modules_from_admin_index if use_admin_index
    modules
  end

  def templates_filter(scanner, use_index, use_admin_index)
    templates = scanner.extract_templates_from_home
    templates = templates | scanner.extract_templates_from_index if use_index
    templates = templates | scanner.extract_templates_from_admin_index if use_admin_index
    templates
  end

  def start
    @use_colours = !opts[:no_colour]
    print_banner

    if opts[:url]
      print_good("URL: #{opts[:url]}")
      print_good("Started: #{Time.now.asctime}")

      scanner = FingerprintScanner.new(opts[:url], opts)
      check_target_redirection(scanner)
      target = scanner.target_uri

      print_line_break
      print_good('Checking if registration is enabled...') if opts[:verbose]
      print_warning("Registration is enabled: #{scanner.target_uri}#{scanner.registration_uri}") if scanner.user_registration_enabled
      print_good('User registration is not enabled.') if !scanner.user_registration_enabled && opts[:verbose]

      print_line_break if opts[:verbose]
      print_good('Looking for interesting headers...') if opts[:verbose]
      interesting_headers = scanner.interesting_headers
      print_good("Found #{interesting_headers.length} interesting headers.")
      interesting_headers.each do |header|
        print_indent("#{header[0]}: #{header[1]}")
      end

      print_line_break if opts[:verbose]
      print_good('Looking for directory listings...') if opts[:verbose]

      administrator_components_listing_enabled = scanner.administrator_components_listing_enabled
      print_warning("Components listing enabled: #{scanner.target_uri}/administrator/components") if administrator_components_listing_enabled

      components_listing_enabled = scanner.components_listing_enabled
      print_warning("Components listing enabled: #{scanner.target_uri}/components") if components_listing_enabled

      administrator_modules_listing_enabled = scanner.administrator_modules_listing_enabled
      print_warning("Modules listing enabled: #{scanner.target_uri}/administrator/modules") if administrator_modules_listing_enabled

      modules_listing_enabled = scanner.modules_listing_enabled  
      print_warning("Modules listing enabled: #{scanner.target_uri}/modules") if modules_listing_enabled

      modules_listing_enabled = scanner.modules_listing_enabled  
      print_warning("Modules listing enabled: #{scanner.target_uri}/modules") if modules_listing_enabled

      administrator_templates_listing_enabled = scanner.administrator_templates_listing_enabled
      print_warning("Templates listing enabled: #{scanner.target_uri}/administrator/templates") if administrator_templates_listing_enabled

      templates_listing_enabled = scanner.templates_listing_enabled
      print_warning("Templates listing enabled: #{scanner.target_uri}/templates") if templates_listing_enabled

      print_line_break
      print_good('Determining Joomla version...') if opts[:verbose]
      print_info('Searching for version in meta data...') if opts[:verbose]
      version = scanner.version_from_meta_tag
      print_good("Joomla version #{version} identified from meta data") if version

      unless version
        version = scanner.version_from_readme
        print_error('No version found in the meta data') if opts[:verbose]
        print_info('Searching for version in README.txt...') if opts[:verbose]
        print_good("Joomla version #{version} identified from README.txt") if version
      end

      print_error('Couldn\'t determine version from README.txt') unless version

      if version
        joomla_vulns = joomla_vulnerabilities(Gem::Version.new(version))
        if joomla_vulns
          print_warning("Found #{joomla_vulns.length} vulnerabilities affecting this version of Joomla!")
          display_vulns(joomla_vulns)
        end
      end

      filters = {
        :components => [],
        :modules => [],
        :templates => []
      }

      if opts[:quiet]
        print_line_break if opts[:verbose]
        print_good 'Building extension filters...' if opts[:verbose]
        filters[:components] = components_filter(scanner, components_listing_enabled, administrator_components_listing_enabled)
        filters[:modules] = modules_filter(scanner, modules_listing_enabled, administrator_modules_listing_enabled)
        filters[:templates] = templates_filter(scanner, templates_listing_enabled, administrator_templates_listing_enabled)
      end

      if opts[:scan_all] || opts[:scan_components]
        scanner = ComponentScanner.new(target, opts)
        print_line_break
        print_good('Scanning for vulnerable components...')
        components = scanner.scan(filters[:components])
        print_warning("Found #{components.length} vulnerable components.")
        print_line_break
        print_horizontal_rule
        components.each { |c| display_detected_extension(c) }
      end

      if opts[:scan_all] || opts[:scan_modules]
        scanner = ModuleScanner.new(target, opts)
        print_line_break
        print_good('Scanning for vulnerable modules...')
        modules = scanner.scan(filters[:modules])
        print_warning("Found #{modules.length} vulnerable modules.")
        print_line_break
        print_horizontal_rule
        modules.each { |m| display_detected_extension(m) }
      end

      if opts[:scan_all] || opts[:scan_templates]
        scanner = TemplateScanner.new(target, opts)
        print_line_break
        print_good('Scanning for vulnerable templates...')
        templates = scanner.scan(filters[:templates])
        print_warning("Found #{templates.length} vulnerable templates.")
        print_line_break
        print_horizontal_rule
        templates.each { |t| display_detected_extension(t) }
      end

      print_line_break
      print_good 'Finished'
    else
      puts opts
    end

    print_line_break
  end
end

app = JoomlaVS.new
app.start
