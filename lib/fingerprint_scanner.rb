require_relative 'scanner'

class FingerprintScanner < Scanner

    def initialize(target_uri)
      super(target_uri)
    end

    def version_from_readme
      req = create_request('/README.txt')
      version = ''
      req.on_complete do |resp|
        match = /(Joomla!?\s)([0-9]+(\.?[0-9]+)?(\.?[0-9]+)?)+\s/.match(resp.body)
        version = match.captures[1]
      end

      req.run
      version
    end
end
