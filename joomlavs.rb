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

  attr_reader :opts
  attr_reader :fingerprint_scanner
  attr_reader :target
  attr_reader :joomla_version

  def initialize
    initialize_options
    @use_colours = !opts[:no_colour]
    @target = opts[:url]
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

  def print_indent_unless_empty(text, var)
    print_indent(text) unless var.empty?
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

  def display_optional_extension_info(e)
    print_indent_unless_empty("Description: #{e[:description]}", e[:description])
    print_indent_unless_empty("Author: #{e[:author]}", e[:author])
    print_indent_unless_empty("Author URL: #{e[:author_url]}", e[:author_url])
  end

  def display_required_extension_info(e)
    print_good("Name: #{e[:name]} - v#{e[:version]}")
    print_indent("Location: #{e[:extension_url]}")
    print_indent("Manifest: #{e[:manifest_url]}")
  end

  def display_detected_extension(e)
    print_line_break
    display_required_extension_info(e)
    display_optional_extension_info(e)
    display_vulns(e[:vulns])
    print_horizontal_rule
  end

  def joomla_vulnerabilities
    json = File.read('data/joomla.json')
    vulns = JSON.parse(json)
    found = []

    vulns.each do |v|
      found.push(v) if ExtensionScanner.version_is_vulnerable(Gem::Version.new(joomla_version), v)
    end

    found
  end

  def print_verbose(text)
    print_info(text) if opts[:verbose]
  end

  def abort_scan
    print_line_break
    print_good('Scan aborted')
    exit(1)
  end

  def update_target_uri(new_uri)
    fingerprint_scanner.update_target_uri new_uri
    print_verbose("Now targetting #{fingerprint_scanner.target_uri}")
  end

  def verify_target_change(new_uri)
    print_info("The remote host tried to redirect to: #{new_uri}")
    answer = read_input('Do you want to follow the redirection? [Y]es [N]o [A]bort: ')
    if answer =~ /^y/i
      update_target_uri(new_uri)
    elsif answer =~ /^a/i
      abort_scan
    end
  end

  def check_target_redirection
    redirected_uri = fingerprint_scanner.target_redirects_to
    return unless redirected_uri

    if opts[:follow_redirection]
      update_target_uri(redirected_uri)
    else
      print_line_break
      verify_target_change(redirected_uri)
    end
  end

  def components_filter
    return [] unless opts[:quiet]
    components = fingerprint_scanner.extract_components_from_home

    if fingerprint_scanner.components_listing_enabled
      components |= fingerprint_scanner.extract_components_from_index
    end

    if fingerprint_scanner.administrator_components_listing_enabled
      components |= fingerprint_scanner.extract_components_from_admin_index
    end

    components
  end

  def modules_filter
    return [] unless opts[:quiet]
    modules = fingerprint_scanner.extract_modules_from_home

    if fingerprint_scanner.modules_listing_enabled
      modules |= fingerprint_scanner.extract_modules_from_index
    end

    if fingerprint_scanner.administrator_modules_listing_enabled
      modules |= fingerprint_scanner.extract_modules_from_admin_index
    end

    modules
  end

  def templates_filter
    return [] unless opts[:quiet]
    templates = fingerprint_scanner.extract_templates_from_home
    
    if fingerprint_scanner.templates_listing_enabled
      templates |= fingerprint_scanner.extract_templates_from_index
    end

    if fingerprint_scanner.administrator_templates_listing_enabled
      templates |= fingerprint_scanner.extract_templates_from_admin_index
    end

    templates
  end

  def check_user_registration
    print_line_break
    print_verbose('Checking if registration is enabled...')
    print_warning("Registration is enabled: #{fingerprint_scanner.target_uri}#{fingerprint_scanner.registration_uri}") if fingerprint_scanner.user_registration_enabled
    print_verbose('User registration is not enabled.') if !fingerprint_scanner.user_registration_enabled
  end

  def inspect_headers
    print_line_break if opts[:verbose]
    print_verbose('Looking for interesting headers...')
    interesting_headers = fingerprint_scanner.interesting_headers
    print_good("Found #{interesting_headers.length} interesting headers.")
    interesting_headers.each do |header|
      print_indent("#{header[0]}: #{header[1]}")
    end
  end

  def check_component_indexes
    if fingerprint_scanner.administrator_components_listing_enabled
      print_warning("Components listing enabled: #{fingerprint_scanner.target_uri}/administrator/components")
    end

    if fingerprint_scanner.components_listing_enabled
      print_warning("Components listing enabled: #{fingerprint_scanner.target_uri}/components")
    end
  end

  def check_module_indexes
    if fingerprint_scanner.administrator_modules_listing_enabled
      print_warning("Modules listing enabled: #{fingerprint_scanner.target_uri}/administrator/modules")
    end

    if fingerprint_scanner.modules_listing_enabled
      print_warning("Modules listing enabled: #{fingerprint_scanner.target_uri}/modules")
    end
  end

  def check_template_indexes
    if fingerprint_scanner.administrator_templates_listing_enabled
      print_warning("Templates listing enabled: #{fingerprint_scanner.target_uri}/administrator/templates")
    end

    if fingerprint_scanner.templates_listing_enabled
      print_warning("Templates listing enabled: #{fingerprint_scanner.target_uri}/templates")
    end
  end

  def check_indexes
    print_line_break if opts[:verbose]
    print_verbose('Looking for directory listings...')

    check_component_indexes
    check_module_indexes
    check_template_indexes
  end

  def determine_joomla_version_from_meta_tags
    print_verbose('Searching for version in meta data...')
    @joomla_version = fingerprint_scanner.version_from_meta_tag

    if joomla_version
      print_good("Joomla version #{@joomla_version} identified from meta data")
    else
      print_verbose('No version found in the meta data')
    end
  end

  def determine_joomla_version_from_readme
    print_verbose('Searching for version in README.txt...')
    @joomla_version = fingerprint_scanner.version_from_readme
    if joomla_version
      print_good("Joomla version #{@joomla_version} identified from README.txt")
    else
      print_verbose('No version found in README.txt')
    end
  end

  def determine_joomla_version
    print_line_break
    print_verbose('Determining Joomla version...')
    determine_joomla_version_from_meta_tags
    determine_joomla_version_from_readme unless @joomla_version
    print_error('Couldn\'t determine version') unless joomla_version
  end

  def execute_fingerprinting_tasks
    @fingerprint_scanner = FingerprintScanner.new(opts[:url], opts)
    check_target_redirection
    @target = fingerprint_scanner.target_uri
    check_user_registration
    inspect_headers
    check_indexes
    determine_joomla_version
  end

  def display_joomla_vulns
    if joomla_version
      joomla_vulns = joomla_vulnerabilities
      if joomla_vulns
        print_warning("Found #{joomla_vulns.length} vulnerabilities affecting this version of Joomla!")
        display_vulns(joomla_vulns)
      end
    end
  end

  def scan_components
    return unless opts[:scan_all] || opts[:scan_components]
    scanner = ComponentScanner.new(target, opts)
    print_line_break
    print_good('Scanning for vulnerable components...')
    components = scanner.scan(components_filter)
    print_warning("Found #{components.length} vulnerable components.")
    print_line_break
    print_horizontal_rule
    components.each { |c| display_detected_extension(c) }
  end

  def scan_modules
    return unless opts[:scan_all] || opts[:scan_modules]
    scanner = ModuleScanner.new(target, opts)
    print_line_break
    print_good('Scanning for vulnerable modules...')
    modules = scanner.scan(modules_filter)
    print_warning("Found #{modules.length} vulnerable modules.")
    print_line_break
    print_horizontal_rule
    modules.each { |m| display_detected_extension(m) }
  end

  def scan_templates
    return unless opts[:scan_all] || opts[:scan_templates]
    scanner = TemplateScanner.new(target, opts)
    print_line_break
    print_good('Scanning for vulnerable templates...')
    templates = scanner.scan(templates_filter)
    print_warning("Found #{templates.length} vulnerable templates.")
    print_line_break
    print_horizontal_rule
    templates.each { |t| display_detected_extension(t) }
  end

  def scan_extensions
    scan_components
    scan_modules
    scan_templates
  end

  def has_target
    !opts[:url].nil? && !opts[:url].empty?
  end

  def start
    execute_fingerprinting_tasks
    display_joomla_vulns
    scan_extensions
  end
end

app = JoomlaVS.new
app.print_banner

if app.has_target
  app.print_good("URL: #{app.target}")
  app.print_good("Started: #{Time.now.asctime}")
  app.start
  app.print_line_break
  app.print_good 'Finished'
else
  puts app.opts
end

app.print_line_break