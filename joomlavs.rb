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
    c.scan
  else
    puts opts
  end
end

main

print "\r\n"