require 'typhoeus'

class Scanner

  def initialize(target_uri)
    @target_uri = target_uri.chomp('/')
    @hydra = Typhoeus::Hydra.hydra
  end

  def target_uri
    @target_uri
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
end