require 'json'
require 'nokogiri'
require 'typhoeus'

class ExtensionScanner

  def initialize(target_uri, data_file)
    @target_uri = target_uri
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
    Typhoeus::Request.new(target_uri.chomp('/') + path, followlocation: true)
  end

  def process_result(ext, res)
    doc = Nokogiri::XML(res)
    print "Found #{ext['name']} #{doc.xpath('//extension/version').text}\r\n"
  end

  def scan
    json = File.read(@data_file)
    extensions = JSON.parse(json)

    extensions.each do |e|
      # Attempt to find the extension named manifest first.
      uri = normalize_uri(extension_uri(e['name']), "#{e['name']}.xml")
      req = create_request(uri)
      req.on_complete do |resp|
        if resp.code == 200
          process_result(e, resp.body)
        else
          # Extension named manifest wasn't found, try to find manifest.xml
          uri = normalize_uri(extension_uri(e['name']), "manifest.xml")
          req = create_request(uri)
          req.on_complete do |resp|
            process_result(e, resp.body) if resp.code == 200
          end

          hydra.queue req
        end
      end

      hydra.queue req
    end

    hydra.run
  end
end