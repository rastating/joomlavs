require 'slop'
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
)
end

def main
  print_banner
  print "\r\n"

  opts = Slop.parse do |o|
    o.string '-u', '--url', 'The Joomla URL/domain to scan.'
  end

  if opts[:url]
    c = ComponentScanner.new(opts[:url])
    puts "Scanning #{c.target_uri}...\r\n"
    c.scan
  else
    puts opts
  end
end

main

print "\r\n"