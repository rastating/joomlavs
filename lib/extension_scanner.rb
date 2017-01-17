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

require 'json'
require 'nokogiri'
require_relative 'scanner'

# This class provides the base functionality required
# to scan for various types of vulnerable Joomla extensions.
class ExtensionScanner < Scanner
  def initialize(target_uri, data_file, opts)
    super(target_uri, opts)
    @data_file = File.join(ExtensionScanner.base_path, data_file)
  end

  def self.base_path
    @@base_path ||= nil
    return @@base_path unless @@base_path.nil?

    base = __FILE__

    while File.symlink?(base)
      base = File.expand_path(File.readlink(base), File.dirname(base))
    end

    @@base_path = File.dirname(File.expand_path(File.join(File.dirname(base))))
  end

  def root_element_xpath
    '//*'
  end

  def get_version_from_manifest(manifest)
    version_text = manifest.xpath("#{root_element_xpath}/version").text

    begin
      version = Gem::Version.new(version_text)
    rescue
      version_number = extract_version_number(version_text)
      version = Gem::Version.new(version_number) if version_number
    ensure
      return version
    end
  end

  def create_extension_from_manifest(xml, extension_path, manifest_uri)
    manifest = Nokogiri::XML(xml)
    {
      version: get_version_from_manifest(manifest),
      name: manifest.xpath("#{root_element_xpath}/name").text,
      author: manifest.xpath("#{root_element_xpath}/author").text,
      author_url: manifest.xpath("#{root_element_xpath}/authorUrl").text,
      extension_url: "#{target_uri}#{extension_path}",
      manifest_url: "#{target_uri}#{manifest_uri}",
      description: manifest.xpath("#{root_element_xpath}/description").text,
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

  def extension_prefix
    ''
  end

  def directory_name
    ''
  end

  def possible_paths(name)
    paths = []
    paths.push(normalize_uri('administrator', directory_name, "#{extension_prefix}#{name}"))
    paths.push(normalize_uri(directory_name, "#{extension_prefix}#{name}"))
    paths
  end

  def queue_manifest_request(manifest_name, paths, name, path_index, &block)
    uri = normalize_uri(paths[path_index], manifest_name)
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
        queue_manifest_request('manifest.xml', paths, name, path_index, &block)
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

  def scan(filter)
    return [] unless filter
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

  def extract_extension_list_from_page(url, pattern)
    matches = []
    req = create_request(url)
    req.on_complete do |resp|
      matches = resp.body.to_enum(:scan, pattern).map { Regexp.last_match.to_s } if resp.code == 200
    end

    req.run
    matches.uniq
  end

  def extract_extensions_from_page(url)
    pattern = /#{extension_prefix}[a-z0-9\-\._]+/i
    matches = extract_extension_list_from_page(url, pattern)
    matches.map { |m| m.sub(/^#{extension_prefix}/i, '') }
  end

  def extract_list_from_admin_index
    extract_extensions_from_page "/administrator/#{directory_name}/"
  end

  def extract_list_from_index
    extract_extensions_from_page "/#{directory_name}/"
  end

  def extract_list_from_home
    extract_extensions_from_page '/'
  end

  def build_filter(use_root_listing, use_admin_listing)
    extensions = extract_list_from_home

    if use_root_listing
      extensions |= extract_list_from_index
    end

    if use_admin_listing
      extensions |= extract_list_from_admin_index
    end

    return nil if extensions.empty?
    extensions
  end
end
