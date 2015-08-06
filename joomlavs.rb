require 'slop'

require_relative 'lib/output'
require_relative 'lib/component_scanner'
require_relative 'lib/module_scanner'
require_relative 'lib/fingerprint_scanner'

def display_vulns(vulns, output)
  vulns.each do |v|
    output.print_line_break
    output.print_line(:error, "Title: #{v['title']}")
    output.print_indent("Reference: https://www.exploit-db.com/exploits/#{v['edbid']}/") if v['edbid']
    
    if v['cveid'] 
      if v['cveid'].kind_of?(Array)
        v['cveid'].each do |cveid|
          output.print_indent("Reference: http://www.cvedetails.com/cve/#{cveid}/")
        end
      else
        output.print_indent("Reference: http://www.cvedetails.com/cve/#{v['cveid']}/")
      end
    end

    if v['osvdbid']
      if v['osvdbid'].kind_of?(Array)
        v['osvdbid'].each do |osvdbid|
          output.print_indent("Reference: http://osvdb.org/#{osvdbid}")
        end
      else
        output.print_indent("Reference: http://osvdb.org/#{v['osvdbid']}")
      end
    end
    
    output.print_line(:info, "Fixed in: #{v['fixed_in']}") if v['fixed_in']
    output.print_line_break
  end
end

def display_detected_extension(e, output)
  output.print_line_break
  output.print_good("Name: #{e[:name]} - v#{e[:version]}")
  output.print_indent("Location: #{e[:extension_url]}")
  output.print_indent("Manifest: #{e[:manifest_url]}")
  output.print_indent("Description: #{e[:description]}") unless e[:description].empty?
  output.print_indent("Author: #{e[:author]}") unless e[:author].empty?
  output.print_indent("Author URL: #{e[:author_url]}") unless e[:author_url].empty?
  
  display_vulns(e[:vulns], output)

  output.print_horizontal_rule(:default)
end

def joomla_vulnerabilities(version)
  json = File.read('data/joomla.json')
  vulns = JSON.parse(json)
  found = Array.new

  vulns.each do |v|
    if v['ranges']
      v['ranges'].each do |r|
        if Gem::Version.new(r['introduced_in']) <= version
          if Gem::Version.new(r['fixed_in']) > version
            found.push(v)
            break
          end
        end
      end
    else
      if v['introduced_in'].nil? or Gem::Version.new(v['introduced_in']) <= version
        if v['fixed_in'].nil? or Gem::Version.new(v['fixed_in']) > version
          found.push(v)
        end
      end
    end
  end

  found
end

def check_target_redirection(scanner, output, opts)
  redirected_uri = scanner.target_redirects_to
  if redirected_uri
    if opts[:follow_redirection]
      scanner.update_target_uri redirected_uri
      output.print_info("Now targetting #{scanner.target_uri}") if opts[:verbose]
    else
      output.print_line_break
      output.print_info("The remote host tried to redirect to: #{redirected_uri}")
      answer = output.read_input('Do you want to follow the redirection? [Y]es [N]o [A]bort: ')
      if answer =~ /^y/i
        scanner.update_target_uri redirected_uri
        output.print_info("Now targetting #{scanner.target_uri}") if opts[:verbose]
      elsif answer =~ /^a/i
        output.print_line_break
        output.print_good('Scan aborted')
        exit(1)
      end
    end
  end
end

def main
  opts = Slop.parse do |o|
    o.separator 'Basic options'
    o.string '-u', '--url', 'The Joomla URL/domain to scan.'
    o.string '--basic-auth', '<username:password> The basic HTTP authentication credentials'
    o.bool '-v', '--verbose', 'Enable verbose mode'

    o.separator 'Enumeration options'
    o.bool '-a', '--scan-all', 'Scan for all vulnerable extensions'
    o.bool '-c', '--scan-components', 'Scan for vulnerable components'
    o.bool '-m', '--scan-modules', 'Scan for vulnerable modules'

    o.separator 'Advanced options'
    o.bool '--follow-redirection', 'Automatically follow redirections'
    o.bool '--no-colour', 'Disable colours in output'
    o.string '--proxy', '<[protocol://]host:port> HTTP, SOCKS4 SOCKS4A and SOCKS5 are supported. If no protocol is given, HTTP will be used'
    o.string '--proxy-auth', '<username:password> The proxy authentication credentials'
    o.integer '-t', '--threads', 'The number of threads to use when multi-threading requests', default: 20
    o.string '--user-agent', 'The user agent string to send with all requests', default: 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0'
  end

  output = Output.new !opts[:no_colour]
  output.print_banner

  if opts[:url]
    output.print_good("URL: #{opts[:url]}")
    output.print_good("Started: #{Time.now.asctime}")

    scanner = FingerprintScanner.new(opts[:url], opts)
    check_target_redirection(scanner, output, opts)
    target = scanner.target_uri

    output.print_line_break
    output.print_good('Checking if registration is enabled...') if opts[:verbose]
    output.print_warning("Registration is enabled: #{scanner.target_uri}#{scanner.registration_uri}") if scanner.user_registration_enabled
    output.print_good('User registration is not enabled.') if !scanner.user_registration_enabled && opts[:verbose]

    output.print_line_break if opts[:verbose]
    output.print_good("Looking for interesting headers...") if opts[:verbose]
    interesting_headers = scanner.interesting_headers
    output.print_good("Found #{interesting_headers.length} interesting headers.")
    interesting_headers.each do | header |
      output.print_indent("#{header[0]}: #{header[1]}")
    end

    output.print_line_break if opts[:verbose]
    output.print_good("Looking for directory listings...") if opts[:verbose]
    output.print_warning("Components listing enabled: #{scanner.target_uri}/administrator/components") if scanner.administrator_components_listing_enabled
    output.print_warning("Components listing enabled: #{scanner.target_uri}/components") if scanner.components_listing_enabled
    output.print_warning("Modules listing enabled: #{scanner.target_uri}/administrator/modules") if scanner.administrator_modules_listing_enabled
    output.print_warning("Modules listing enabled: #{scanner.target_uri}/modules") if scanner.modules_listing_enabled

    output.print_line_break
    output.print_good("Determining Joomla version...") if opts[:verbose]
    version = scanner.version_from_readme
    output.print_good("Joomla version #{version} identified from README.txt") if version
    output.print_error("Couldn't determine version from README.txt") unless version

    if version
      joomla_vulns = joomla_vulnerabilities(Gem::Version.new(version))
      if joomla_vulns
        output.print_warning("Found #{joomla_vulns.length} vulnerabilities affecting this version of Joomla!")
        display_vulns(joomla_vulns, output)
      end
    end

    if opts[:scan_all] || opts[:scan_components]
      scanner = ComponentScanner.new(target, opts)
      output.print_line_break
      output.print_good("Scanning for vulnerable components...")
      components = scanner.scan
      output.print_warning("Found #{components.length} vulnerable components.")
      output.print_line_break
      output.print_horizontal_rule(:default)
      components.each { |c| display_detected_extension(c, output) }
    end

    if opts[:scan_all] || opts[:scan_modules]
      scanner = ModuleScanner.new(target, opts)
      output.print_line_break
      output.print_good("Scanning for vulnerable modules...")
      modules = scanner.scan
      output.print_warning("Found #{modules.length} vulnerable modules.")
      output.print_line_break
      output.print_horizontal_rule(:default)
      modules.each { |m| display_detected_extension(m, output) }
    end
  else
    puts opts
  end
end

main

print "\r\n"