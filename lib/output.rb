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

require 'colorize'
require 'readline'

# This class provides functionality to output
# to the screen in a consistent style.
class Output
  def initialize (use_colours = true)
    @use_colours = use_colours
  end

  def use_colours
    @use_colours
  end

  def print_line(type, text, new_line = true)
    if type == :good
      print '[+] '.green if use_colours
      print '[+] ' unless use_colours
    elsif type == :warning
      print '[!] '.yellow if use_colours
      print '[!] ' unless use_colours
    elsif type == :info
      print '[i] '.cyan if use_colours
      print '[i] ' unless use_colours
    elsif type == :error
      print '[!] '.red if use_colours
      print '[!] ' unless use_colours
    elsif type == :indent
      print ' |  '.light_white if use_colours
      print ' |  ' unless use_colours
    elsif type == :prompt
      print '[?] '.light_white if use_colours
      print '[?] ' unless use_colours
    else
      print '    '
    end

    print "#{text}".light_white if use_colours
    print "#{text}" unless use_colours
    print "\r\n" if new_line
  end

  def print_banner
    banner = %(
----------------------------------------------------------------------

     ██╗ ██████╗  ██████╗ ███╗   ███╗██╗      █████╗ ██╗   ██╗███████╗
     ██║██╔═══██╗██╔═══██╗████╗ ████║██║     ██╔══██╗██║   ██║██╔════╝
     ██║██║   ██║██║   ██║██╔████╔██║██║     ███████║██║   ██║███████╗
██   ██║██║   ██║██║   ██║██║╚██╔╝██║██║     ██╔══██║╚██╗ ██╔╝╚════██║
╚█████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║███████╗██║  ██║ ╚████╔╝ ███████║
 ╚════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝

----------------------------------------------------------------------

)
    print banner.light_white if use_colours
    print banner unless use_colours
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
