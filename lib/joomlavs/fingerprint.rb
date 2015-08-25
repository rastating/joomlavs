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
  module Fingerprint
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

    def check_indexes
      print_line_break if opts[:verbose]
      print_verbose('Looking for directory listings...')

      indexes = [
        '/components/',
        '/administrator/components/',
        '/modules/',
        '/administrator/modules/',
        '/templates/',
        '/administrator/templates/'
      ]

      indexes.each do |i|
        if fingerprint_scanner.directory_listing_enabled(i)
          print_warning("Listing enabled: #{fingerprint_scanner.target_uri}#{i}")
        end
      end
    end
  end
end
