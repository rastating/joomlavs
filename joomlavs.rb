require 'slop'
require 'colorize'
require_relative 'lib/component_scanner'
require_relative 'lib/module_scanner'
require_relative 'lib/fingerprint_scanner'

def print_banner
  print %(
----------------------------------------------------------------------

     ██╗ ██████╗  ██████╗ ███╗   ███╗██╗      █████╗ ██╗   ██╗███████╗
     ██║██╔═══██╗██╔═══██╗████╗ ████║██║     ██╔══██╗██║   ██║██╔════╝
     ██║██║   ██║██║   ██║██╔████╔██║██║     ███████║██║   ██║███████╗
██   ██║██║   ██║██║   ██║██║╚██╔╝██║██║     ██╔══██║╚██╗ ██╔╝╚════██║
╚█████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║███████╗██║  ██║ ╚████╔╝ ███████║
 ╚════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝

                                          Joomla Vulnerability Scanner
                                                           Version 0.1

----------------------------------------------------------------------

).light_white
end

def print_line(type, text)
  if type == :good
    print '[+] '.green
  elsif type == :warning
    print '[!] '.yellow
  elsif type == :info
    print '[i] '.cyan
  elsif type == :error
    print '[!] '.red
  elsif type == :indent
    print ' |  '.light_white
  else
    print '    '
  end
      
  print "#{text}\r\n".light_white
end

def display_detected_extension(e)
  print_line(:default, '')
  print_line(:good, "Name: #{e[:name]} - v#{e[:version]}")
  print_line(:indent, "Location: #{e[:extension_url]}")
  print_line(:indent, "Manifest: #{e[:manifest_url]}")
  print_line(:indent, "Description: #{e[:description]}") unless e[:description].empty?
  print_line(:indent, "Author: #{e[:author]}") unless e[:author].empty?
  print_line(:indent, "Author URL: #{e[:author_url]}") unless e[:author_url].empty?
  
  e[:vulns].each do |v|
    print_line(:default, '')
    print_line(:error, "Title: #{v['title']}")
    print_line(:indent, "Reference: https://www.exploit-db.com/exploits/#{v['edbid']}") if v['edbid']
    print_line(:indent, "Reference: http://osvdb.org/#{v['osvdbid']}") if v['osvdbid']
    print_line(:info, "Fixed in: #{v['fixed_in']}") if v['fixed_in']
    print_line(:default, '')
  end

  print_line(:default, '------------------------------------------------------------------')
end

def main
  print_banner

  opts = Slop.parse do |o|
    o.string '-u', '--url', 'The Joomla URL/domain to scan.'
  end

  if opts[:url]
    print_line(:good, "URL: #{opts[:url]}")
    print_line(:good, "Started: #{Time.now.asctime}")

    scanner = FingerprintScanner.new(opts[:url])

    print_line(:default, '')
    print_line(:good, "Detecting version number from README.txt...")
    version = scanner.version_from_readme
    print_line(:warning, "Website appears to be running version #{version} of Joomla!") if version
    print_line(:error, "Couldn't determine version from README.txt") unless version

    print_line(:default, '')
    print_line(:good, "Looking for interesting headers...")
    interesting_headers = scanner.interesting_headers
    print_line(:warning, "Found #{interesting_headers.length} interesting headers.")
    interesting_headers.each do | header |
      print_line(:indent, "#{header[0]}: #{header[1]}")
    end

    scanner = ComponentScanner.new(opts[:url])
    print_line(:default, '')
    print_line(:good, "Scanning for vulnerable components...")
    components = scanner.scan
    print_line(:warning, "Found #{components.length} vulnerable components.")
    print_line(:default, '')
    print_line(:default, '------------------------------------------------------------------')
    components.each { |c| display_detected_extension(c) }

    scanner = ModuleScanner.new(opts[:url])
    print_line(:default, '')
    print_line(:good, "Scanning for vulnerable modules...")
    modules = scanner.scan
    print_line(:warning, "Found #{modules.length} vulnerable modules.")
    print_line(:default, '')
    print_line(:default, '------------------------------------------------------------------')
    modules.each { |m| display_detected_extension(m) }

  else
    puts opts
  end
end

main

print "\r\n"