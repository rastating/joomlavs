require 'slop'
require 'colorize'
require_relative 'lib/component_scanner'

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

def main
  print_banner

  opts = Slop.parse do |o|
    o.string '-u', '--url', 'The Joomla URL/domain to scan.'
  end

  if opts[:url]
    c = ComponentScanner.new(opts[:url])
    print_line(:good, "URL: #{c.target_uri}")
    print_line(:good, "Started: #{Time.now.asctime}")
    components = c.scan

    print_line(:default, '')
    print_line(:warning, "Found #{components.length} vulnerable components.")
    print_line(:default, '')
    print_line(:default, '------------------------------------------------------------------')

    components.each do |c|
      print_line(:default, '')
      print_line(:good, "Name: #{c[:name]} - v#{c[:version]}")
      print_line(:indent, "Location: #{c[:extension_url]}")
      print_line(:indent, "Manifest: #{c[:manifest_url]}")
      print_line(:indent, "Description: #{c[:description]}") unless c[:description].empty?
      print_line(:indent, "Author: #{c[:author]}") unless c[:author].empty?
      print_line(:indent, "Author URL: #{c[:author_url]}") unless c[:author_url].empty?
      print_line(:default, '')
      
      c[:vulns].each do |v|
        print_line(:default, '')
        print_line(:error, "Title: #{v['title']}")
        print_line(:indent, "Reference: https://www.exploit-db.com/exploits/#{v['edbid']}") if v['edbid']
        print_line(:indent, "Reference: http://osvdb.org/#{v['osvdbid']}") if v['osvdbid']
        print_line(:info, "Fixed in: #{v['fixed_in']}") if v['fixed_in']
        print_line(:default, '')
      end

      print_line(:default, '------------------------------------------------------------------')
    end
  else
    puts opts
  end
end

main

print "\r\n"