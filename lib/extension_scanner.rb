require 'json'
require 'nokogiri'
require_relative 'scanner'

class ExtensionScanner < Scanner

  def initialize(target_uri, data_file)
    super(target_uri)
    @data_file = data_file
  end

  def process_result(ext, extension_path, manifest_uri, res)
    manifest = Nokogiri::XML(res)
    extension = Hash.new
    extension[:version] = Gem::Version.new(manifest.xpath('//extension/version').text)
    extension[:name] = manifest.xpath('//extension/name').text
    extension[:author] = manifest.xpath('//extension/author').text
    extension[:author_url] = manifest.xpath('//extension/authorUrl').text
    extension[:extension_url] = target_uri + extension_path
    extension[:manifest_url] = target_uri + manifest_uri
    extension[:description] = manifest.xpath('//extension/description').text
    extension[:vulns] = Array.new

    ext['vulns'].each do |v|
      if v['introduced_in'].nil? or Gem::Version.new(v['introduced_in']) <= extension[:version]
        if v['fixed_in'].nil? or Gem::Version.new(v['fixed_in']) > extension[:version]
          extension[:vulns].push(v)
        end
      end
    end

    extension
  end

  def possible_paths(name)
    nil
  end

  def queue_requests(name, path_index = 0, &block)
    paths = possible_paths(name)
    if (path_index < paths.length)
      # Attempt to find the extension named manifest first.
      uri = normalize_uri(paths[path_index], "#{name}.xml")
      req = create_request(uri)
      req.on_complete do |resp|
        if resp.code == 200
          block.call(resp, paths[path_index], uri)
        else
          # Extension named manifest wasn't found, try to find manifest.xml
          uri = normalize_uri(paths[path_index], "manifest.xml")
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
  end

  def scan
    json = File.read(@data_file)
    extensions = JSON.parse(json)
    detected = Array.new
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
