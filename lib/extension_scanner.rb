require 'json'
require 'nokogiri'
require 'typhoeus'

class ExtensionScanner

  def initialize(target_uri, data_file)
    @target_uri = target_uri.chomp('/')
    @data_file = data_file
    @extensions_uri = ''
    @hydra = Typhoeus::Hydra.hydra
  end

  def target_uri
    @target_uri
  end

  def extensions_uri
    @extensions_uri
  end

  def extension_uri(name)
    normalize_uri(extensions_uri, name)
  end

  def hydra
    @hydra
  end

  def normalize_uri(*parts)
    uri = parts * "/"
    uri = uri.gsub!("//", "/") while uri.index("//")

    # Makes sure there's a starting slash
    unless uri[0,1] == '/'
      uri = '/' + uri
    end

    uri
  end

  def create_request(path)
    Typhoeus::Request.new(target_uri + path, followlocation: true)
  end

  def process_result(ext, uri, res)
    manifest = Nokogiri::XML(res)
    extension = Hash.new
    extension[:version] = Gem::Version.new(manifest.xpath('//extension/version').text)
    extension[:name] = manifest.xpath('//extension/name').text
    extension[:author] = manifest.xpath('//extension/author').text
    extension[:author_url] = manifest.xpath('//extension/authorUrl').text
    extension[:extension_url] = target_uri + extension_uri(ext['name'])
    extension[:manifest_url] = target_uri + uri
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

  def scan
    json = File.read(@data_file)
    extensions = JSON.parse(json)
    detected = Array.new
    lock = Mutex.new

    extensions.each do |e|
      # Attempt to find the extension named manifest first.
      uri = normalize_uri(extension_uri(e['name']), "#{e['name']}.xml")
      req = create_request(uri)
      req.on_complete do |resp|
        if resp.code == 200
          lock.synchronize do
            res = process_result(e, uri, resp.body)
            detected.push(res) if res[:vulns].length > 0
          end
        else
          # Extension named manifest wasn't found, try to find manifest.xml
          uri = normalize_uri(extension_uri(e['name']), "manifest.xml")
          req = create_request(uri)
          req.on_complete do |resp|
            lock.synchronize do
              if resp.code == 200
                res = process_result(e, uri, resp.body)
                detected.push(res) if res[:vulns].length > 0
              end
            end
          end

          hydra.queue req
        end
      end

      hydra.queue req
    end

    hydra.run
    detected
  end
end