# This file is part of JoomlaVS.

# JoomlaVS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# JoomlaVS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with JoomlaVS.  If not, see <http://www.gnu.org/licenses/>.

module JoomlaVS
  module Target
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
  end
end
