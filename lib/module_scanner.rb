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

require_relative 'extension_scanner'

# This class provides functionality to scan for
# vulnerable Joomla modules.
class ModuleScanner < ExtensionScanner
  def initialize(target_uri, opts)
    super(target_uri, 'data/modules.json', opts)
  end

  def extension_prefix
    'mod_'
  end

  def directory_name
    'modules'
  end
end
