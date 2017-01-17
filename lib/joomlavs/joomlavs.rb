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
  attr_reader :opts
  attr_reader :fingerprint_scanner
  attr_reader :target
  attr_reader :joomla_version

  def abort_scan
    print_line_break
    print_good('Scan aborted')
    exit(1)
  end

  def has_target
    !opts[:url].nil? && !opts[:url].empty?
  end

  def joomla_vulnerabilities
    json = File.read(File.join(ExtensionScanner.base_path, 'data/joomla.json'))
    vulns = JSON.parse(json)
    found = []

    vulns.each do |v|
      found.push(v) if ExtensionScanner.version_is_vulnerable(Gem::Version.new(joomla_version), v)
    end

    found
  end

  def display_joomla_vulns
    return unless joomla_version

    joomla_vulns = joomla_vulnerabilities
    return unless joomla_vulns

    print_warning("Found #{joomla_vulns.length} vulnerabilities affecting this version of Joomla!")
    display_vulns(joomla_vulns)
  end
end
