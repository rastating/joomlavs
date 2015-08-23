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
  module Modules
    def modules_filter
      return [] unless opts[:quiet]
      modules = fingerprint_scanner.extract_modules_from_home

      if fingerprint_scanner.modules_listing_enabled
        modules |= fingerprint_scanner.extract_modules_from_index
      end

      if fingerprint_scanner.administrator_modules_listing_enabled
        modules |= fingerprint_scanner.extract_modules_from_admin_index
      end

      modules
    end

    def check_module_indexes
      if fingerprint_scanner.administrator_modules_listing_enabled
        print_warning("Modules listing enabled: #{fingerprint_scanner.target_uri}/administrator/modules")
      end

      if fingerprint_scanner.modules_listing_enabled
        print_warning("Modules listing enabled: #{fingerprint_scanner.target_uri}/modules")
      end
    end

    def scan_modules
      return unless opts[:scan_all] || opts[:scan_modules]
      scanner = ModuleScanner.new(target, opts)
      print_line_break
      print_good('Scanning for vulnerable modules...')
      modules = scanner.scan(modules_filter)
      print_warning("Found #{modules.length} vulnerable modules.")
      print_line_break
      print_horizontal_rule
      modules.each { |m| display_detected_extension(m) }
    end
  end
end
