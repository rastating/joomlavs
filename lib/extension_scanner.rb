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

require 'json'
require 'nokogiri'
require_relative 'scanner'

# This class provides the base functionality required
# to scan for various types of vulnerable Joomla extensions.
class ExtensionScanner < Scanner
  def initialize(target_uri, data_file, opts)
    super(target_uri, opts)
    @data_file = data_file
  end

  def process_result(ext, extension_path, manifest_uri, res)
    manifest = Nokogiri::XML(res)
    extension = {}
    extension[:version] = Gem::Version.new(manifest.xpath('//extension/version').text)
    extension[:name] = manifest.xpath('//extension/name').text
    extension[:author] = manifest.xpath('//extension/author').text
    extension[:author_url] = manifest.xpath('//extension/authorUrl').text
    extension[:extension_url] = target_uri + extension_path
    extension[:manifest_url] = target_uri + manifest_uri
    extension[:description] = manifest.xpath('//extension/description').text
    extension[:vulns] = []

    ext['vulns'].each do |v|
      extension[:vulns].push(v) if ExtensionScanner.version_is_vulnerable(extension[:version], v)
    end

    extension
  end

  def possible_paths(name)
    nil
  end

  def queue_requests(name, path_index = 0, &block)
    paths = possible_paths(name)
    return unless path_index < paths.length

    # Attempt to find the extension named manifest first.
    uri = normalize_uri(paths[path_index], "#{name}.xml")
    req = create_request(uri)
    req.on_complete do |resp|
      if resp.code == 200
        block.call(resp, paths[path_index], uri)
      else
        # Extension named manifest wasn't found, try to find manifest.xml
        uri = normalize_uri(paths[path_index], 'manifest.xml')
        req = create_request(uri)
        req.on_complete do |resp|
          if resp.code == 200
            block.call(resp, paths[path_index], uri)
          else
            # Neither manifests could be found, try the next path
            queue_requests(name, path_index + 1, &block)
          end
        end

        hydra.queue req
      end
    end

    hydra.queue req
  end

  def self.version_is_vulnerable(version, vuln)
    found = false
    if vuln['ranges']
      vuln['ranges'].each do |r|
        if Gem::Version.new(r['introduced_in']) <= version
          if Gem::Version.new(r['fixed_in']) > version
            found = true
            break
          end
        end
      end
    else
      if vuln['introduced_in'].nil? || Gem::Version.new(vuln['introduced_in']) <= version
        if vuln['fixed_in'].nil? || Gem::Version.new(vuln['fixed_in']) > version
          found = true
        end
      end
    end

    found
  end

  def data_file_json
    JSON.parse(File.read(@data_file))
  end

  def scan
    extensions = data_file_json
    detected = []
    lock = Mutex.new

    extensions.each do |e|
      queue_requests(e['name']) do |resp, extension_path, manifest_uri|
        lock.synchronize do
          res = process_result(e, extension_path, manifest_uri, resp.body)
          detected.push(res) if res[:vulns].length > 0
        end
      end
    end

    hydra.run
    detected
  end
end
