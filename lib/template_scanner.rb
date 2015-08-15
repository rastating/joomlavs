# This file is part of Joomla VS.

# Joomla VS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Joomla VS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Joomla VS.  If not, see <http://www.gnu.org/licenses/>.

require_relative 'extension_scanner'

# This class provides functionality to scan for
# vulnerable Joomla templates.
class TemplateScanner < ExtensionScanner
  def initialize(target_uri, opts)
    super(target_uri, 'data/templates.json', opts)
  end

  def possible_paths(name)
    paths = []
    paths.push(normalize_uri('administrator', 'templates', name))
    paths.push(normalize_uri('templates', name))
    paths
  end

  def queue_requests(name, path_index = 0, &block)
    paths = possible_paths(name)
    return unless path_index < paths.length

    uri = normalize_uri(paths[path_index], 'templateDetails.xml')
    req = create_request(uri)
    req.on_complete do |resp|
      if resp.code == 200
        block.call(resp, paths[path_index], uri)
      else
        queue_requests(name, path_index + 1, &block)
      end
    end

    hydra.queue req
  end
end
