require 'colorize'
require 'readline'

class Output
  def print_line(type, text, new_line = true)
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
    elsif type == :prompt
      print '[?] '.light_white
    else
      print '    '
    end
        
    print "#{text}".light_white
    print "\r\n" if new_line
  end

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

  def read_input(prompt)
    print_line(:prompt, prompt, false)
    Readline.readline
  end

  def print_good(text)
    print_line(:good, text)
  end

  def print_warning(text)
    print_line(:warning, text)
  end

  def print_info(text)
    print_line(:info, text)
  end

  def print_error(text)
    print_line(:error, text)
  end

  def print_indent(text)
    print_line(:indent, text)
  end

  def print_line_break
    print_line(:default, '')
  end

  def print_horizontal_rule(style)
    print_line(style, '------------------------------------------------------------------')
  end
end