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

  def create_extension_from_manifest(xml, extension_path, manifest_uri)
    manifest = Nokogiri::XML(xml)
    {
      version: Gem::Version.new(manifest.xpath('//extension/version').text),
      name: manifest.xpath('//extension/name').text,
      author: manifest.xpath('//extension/author').text,
      author_url: manifest.xpath('//extension/authorUrl').text,
      extension_url: "#{target_uri}#{extension_path}",
      manifest_url: "#{target_uri}#{manifest_uri}",
      description: manifest.xpath('//extension/description').text,
      vulns: []
    }
  end

  def process_result(ext, extension_path, manifest_uri, res)
    extension = create_extension_from_manifest(res, extension_path, manifest_uri)
    ext['vulns'].each do |v|
      extension[:vulns].push(v) if ExtensionScanner.version_is_vulnerable(extension[:version], v)
    end
    extension
  end

  def possible_paths(name)
    nil
  end

  def queue_manifest_request(paths, name, path_index, &block)
    uri = normalize_uri(paths[path_index], 'manifest.xml')
    req = create_request(uri)
    req.on_complete do |resp|
      if resp.code == 200
        # We found the manifest, invoke the callback.
        block.call(resp, paths[path_index], uri)
      else
        # Neither manifests could be found, try the next path
        queue_requests(name, path_index + 1, &block)
      end
    end

    hydra.queue req
  end

  def queue_requests(name, path_index = 0, &block)
    paths = possible_paths(name)
    return unless path_index < paths.length

    # Attempt to find the extension named manifest first.
    uri = normalize_uri(paths[path_index], "#{name}.xml")
    req = create_request(uri)
    req.on_complete do |resp|
      if resp.code == 200
        # We found the named manifest, invoke the callback.
        block.call(resp, paths[path_index], uri)
      else
        # Extension named manifest wasn't found, try to find manifest.xml
        queue_manifest_request(paths, name, path_index, &block)
      end
    end

    hydra.queue req
  end

  def self.version_in_range(version, range)
    in_range = false

    if range['introduced_in'].nil? || Gem::Version.new(range['introduced_in']) <= version
      if range['fixed_in'].nil? || Gem::Version.new(range['fixed_in']) > version
        in_range = true
      end
    end

    in_range
  end

  def self.version_is_vulnerable(version, vuln)
    found = false

    if vuln['ranges']
      vuln['ranges'].each do |range|
        found = version_in_range(version, range)
        break if found
      end
    else
      found = version_in_range(version, vuln)
    end

    found
  end

  def data_file_json
    JSON.parse(File.read(@data_file))
  end

  def apply_filter(extensions, filter)
    extensions.delete_if { |e| !filter.include? e['name'] } unless filter.empty?
    extensions
  end

  def scan(filter = [])
    extensions = apply_filter(data_file_json, filter)
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
