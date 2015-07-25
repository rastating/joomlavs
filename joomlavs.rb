require 'slop'

require_relative 'lib/output'
require_relative 'lib/component_scanner'
require_relative 'lib/module_scanner'
require_relative 'lib/fingerprint_scanner'

def display_detected_extension(e, output)
  output.print_line_break
  output.print_good("Name: #{e[:name]} - v#{e[:version]}")
  output.print_indent("Location: #{e[:extension_url]}")
  output.print_indent("Manifest: #{e[:manifest_url]}")
  output.print_indent("Description: #{e[:description]}") unless e[:description].empty?
  output.print_indent("Author: #{e[:author]}") unless e[:author].empty?
  output.print_indent("Author URL: #{e[:author_url]}") unless e[:author_url].empty?
  
  e[:vulns].each do |v|
    output.print_line_break
    output.print_line(:error, "Title: #{v['title']}")
    output.print_indent("Reference: https://www.exploit-db.com/exploits/#{v['edbid']}") if v['edbid']
    output.print_indent("Reference: http://osvdb.org/#{v['osvdbid']}") if v['osvdbid']
    output.print_line(:info, "Fixed in: #{v['fixed_in']}") if v['fixed_in']
    output.print_line_break
  end

  output.print_horizontal_rule(:default)
end

def main
  output = Output.new
  output.print_banner

  opts = Slop.parse do |o|
    o.string '-u', '--url', 'The Joomla URL/domain to scan.'
  end

  if opts[:url]
    output.print_good("URL: #{opts[:url]}")
    output.print_good("Started: #{Time.now.asctime}")

    scanner = FingerprintScanner.new(opts[:url])

    output.print_line_break
    output.print_good("Determining Joomla version...")
    version = scanner.version_from_readme
    output.print_warning("Website appears to be running version #{version} of Joomla!") if version
    output.print_error("Couldn't determine version from README.txt") unless version

    output.print_line_break
    output.print_good('Checking if user registration is enabled...')
    output.print_warning("User registration is available at #{scanner.target_uri}#{scanner.registration_uri}") if scanner.user_registration_enabled
    output.print_good('User registration is not enabled.') unless scanner.user_registration_enabled

    output.print_line_break
    output.print_good("Looking for interesting headers...")
    interesting_headers = scanner.interesting_headers
    output.print_warning("Found #{interesting_headers.length} interesting headers.")
    interesting_headers.each do | header |
      output.print_indent("#{header[0]}: #{header[1]}")
    end

    output.print_line_break
    output.print_good("Looking for directory listings...")
    output.print_warning("Components listing enabled: #{scanner.target_uri}/administrator/components") if scanner.administrator_components_listing_enabled
    output.print_warning("Components listing enabled: #{scanner.target_uri}/components") if scanner.components_listing_enabled
    output.print_warning("Modules listing enabled: #{scanner.target_uri}/administrator/modules") if scanner.administrator_modules_listing_enabled
    output.print_warning("Modules listing enabled: #{scanner.target_uri}/modules") if scanner.modules_listing_enabled

    scanner = ComponentScanner.new(opts[:url])
    output.print_line_break
    output.print_good("Scanning for vulnerable components...")
    components = scanner.scan
    output.print_warning("Found #{components.length} vulnerable components.")
    output.print_line_break
    output.print_horizontal_rule(:default)
    components.each { |c| display_detected_extension(c, output) }

    scanner = ModuleScanner.new(opts[:url])
    output.print_line_break
    output.print_good("Scanning for vulnerable modules...")
    modules = scanner.scan
    output.print_warning("Found #{modules.length} vulnerable modules.")
    output.print_line_break
    output.print_horizontal_rule(:default)
    modules.each { |m| display_detected_extension(m, output) }
  else
    puts opts
  end
end

main

print "\r\n"