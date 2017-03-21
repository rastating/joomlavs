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
  module Version
    def determine_joomla_version_from_language
      print_verbose('Searching for version in language file (en-GB-xml)...')
      @joomla_version = fingerprint_scanner.version_from_language
      if joomla_version
        print_good("Joomla version #{@joomla_version} identified from language file (en-GB.xml)")
      else
        print_verbose('No version found in language file')
      end
    end

    def determine_joomla_version_from_meta_tags
      print_verbose('Searching for version in meta data...')
      @joomla_version = fingerprint_scanner.version_from_meta_tag

      if joomla_version
        print_good("Joomla version #{@joomla_version} identified from meta data")
      else
        print_verbose('No version found in the meta data')
      end
    end

    def determine_joomla_version_from_readme
      print_verbose('Searching for version in README.txt...')
      @joomla_version = fingerprint_scanner.version_from_readme
      if joomla_version
        print_good("Joomla version #{@joomla_version} identified from README.txt")
      else
        print_verbose('No version found in README.txt')
      end
    end

    def determine_joomla_version_from_admin_manifest
      print_verbose('Searching for version in admin manifest...')
      @joomla_version = fingerprint_scanner.version_from_manifest
      if joomla_version
        print_good("Joomla version #{@joomla_version} identified from admin manifest")
      else
        print_verbose('No version found in admin manifest')
      end
    end

    def determine_joomla_version
      print_line_break
      print_verbose('Determining Joomla version...')
      determine_joomla_version_from_admin_manifest
      determine_joomla_version_from_language unless @joomla_version
      determine_joomla_version_from_meta_tags unless @joomla_version
      determine_joomla_version_from_readme unless @joomla_version
      print_error('Couldn\'t determine version') unless joomla_version
    end
  end
end
