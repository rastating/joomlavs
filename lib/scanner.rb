require 'typhoeus'

class Scanner
  attr_accessor :target_uri

  def initialize(target_uri, follow_redirection)
    update_target_uri target_uri
    @follow_redirection = follow_redirection
    @hydra = Typhoeus::Hydra.hydra
  end

  def target_uri
    @target_uri
  end

  def update_target_uri(value)
    @target_uri = value.chomp('/')
  end

  def hydra
    @hydra
  end

  def follow_redirection
    @follow_redirection
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
    Typhoeus::Request.new(target_uri + path, followlocation: follow_redirection ? true : false)
  end

  def target_redirects_to
    req = create_request('/')
    req.options['followlocation'] = false
    loc = nil
    req.on_complete do |resp|
      if resp.code == 301 || resp.code == 302
        loc = resp.headers['location']
      end
    end

    req.run
    loc
  end
end