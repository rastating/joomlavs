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
  module Components
    def components_filter
      return [] unless opts[:quiet]
      components = fingerprint_scanner.extract_components_from_home

      if fingerprint_scanner.components_listing_enabled
        components |= fingerprint_scanner.extract_components_from_index
      end

      if fingerprint_scanner.administrator_components_listing_enabled
        components |= fingerprint_scanner.extract_components_from_admin_index
      end

      return nil if components.empty?
      components
    end

    def scan_components
      return unless opts[:scan_all] || opts[:scan_components]
      scanner = ComponentScanner.new(target, opts)
      print_line_break
      print_good('Scanning for vulnerable components...')
      components = scanner.scan(components_filter)
      print_warning("Found #{components.length} vulnerable components.")
      print_line_break
      print_horizontal_rule
      components.each { |c| display_detected_extension(c) }
    end

    def check_component_indexes
      if fingerprint_scanner.administrator_components_listing_enabled
        print_warning("Components listing enabled: #{fingerprint_scanner.target_uri}/administrator/components")
      end

      if fingerprint_scanner.components_listing_enabled
        print_warning("Components listing enabled: #{fingerprint_scanner.target_uri}/components")
      end
    end
  end
end
