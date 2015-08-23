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
# vulnerable Joomla templates.
class TemplateScanner < ExtensionScanner
  def initialize(target_uri, opts)
    super(target_uri, 'data/templates.json', opts)
  end

  def directory_name
    'templates'
  end

  def queue_requests(name, path_index = 0, &block)
    paths = possible_paths(name)
    return unless path_index < paths.length
    queue_manifest_request('templateDetails.xml', paths, name, path_index, &block)
  end
end
