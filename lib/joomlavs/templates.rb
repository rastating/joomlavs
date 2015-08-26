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
  module Templates
    def build_templates_filter(scanner)
      scanner.build_filter(fingerprint_scanner.templates_listing_enabled, fingerprint_scanner.administrator_templates_listing_enabled)
    end

    def scan_templates
      scan(:templates, TemplateScanner, opts[:scan_templates])
    end
  end
end
