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
  module Extensions
    def display_reference(ref, base_url = nil)
      return unless ref
      if ref.is_a?(Array)
        ref.each do |id|
          print_indent("Reference: #{base_url}#{id}")
        end
      else
        print_indent("Reference: #{base_url}#{ref}")
      end
    end

    def display_vulns(vulns)
      vulns.each do |v|
        print_line_break
        print_error("Title: #{v['title']}")
        display_reference v['edbid'], 'https://www.exploit-db.com/exploits/'
        display_reference v['cveid'], 'http://www.cvedetails.com/cve/CVE-'
        display_reference v['url']
        print_info("Fixed in: #{v['fixed_in']}") if v['fixed_in']
        print_line_break
      end
    end

    def display_optional_extension_info(e)
      print_indent_unless_empty("Description: #{e[:description]}", e[:description])
      print_indent_unless_empty("Author: #{e[:author]}", e[:author])
      print_indent_unless_empty("Author URL: #{e[:author_url]}", e[:author_url])
    end

    def display_required_extension_info(e)
      print_good("Name: #{e[:name]} - v#{e[:version]}")
      print_indent("Location: #{e[:extension_url]}")
      print_indent("Manifest: #{e[:manifest_url]}")
    end

    def display_detected_extension(e)
      print_line_break
      display_required_extension_info(e)
      display_optional_extension_info(e)
      display_vulns(e[:vulns])
      print_horizontal_rule
    end

    def should_scan(scan_flag, filter)
      if scan_flag || opts[:scan_all]
        return !opts[:quiet] || (opts[:quiet] && filter)
      end
    end

    def build_filter(scanner)
      return [] unless opts[:quiet]
      if scanner.instance_of? ComponentScanner
        return build_components_filter(scanner)
      elsif scanner.instance_of? ModuleScanner
        return build_modules_filter(scanner)
      elsif scanner.instance_of? TemplateScanner
        return build_templates_filter(scanner)
      end
    end

    def scan(extension_type, scanner_class, scan_flag)
      scanner = scanner_class.new(target, opts)
      filter = build_filter(scanner)
      return unless should_scan(scan_flag, filter)

      print_line_break
      print_good("Scanning for vulnerable #{extension_type}...")
      extensions = scanner.scan(filter)
      print_warning("Found #{extensions.length} vulnerable #{extension_type}.")
      print_line_break
      print_horizontal_rule
      extensions.each { |e| display_detected_extension(e) }
    end
  end
end
