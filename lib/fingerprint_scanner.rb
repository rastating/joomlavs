require_relative 'scanner'

class FingerprintScanner < Scanner

    def initialize(target_uri)
      super(target_uri)
    end

    def common_resp_headers
      [
        'Access-Control-Allow-Origin',
        'Accept-Patch',
        'Accept-Ranges',
        'Age',
        'Allow',
        'Cache-Control',
        'Connection',
        'Content-Disposition',
        'Content-Encoding',
        'Content-Language',
        'Content-Length',
        'Content-Location',
        'Content-MD5',
        'Content-Range',
        'Content-Type',
        'Date',
        'ETag',
        'Expires',
        'Last-Modified',
        'Link',
        'Location',
        'P3P',
        'Pragma',
        'Proxy-Authenticate',
        'Public-Key-Pins',
        'Refresh',
        'Retry-After',
        'Set-Cookie',
        'Status',
        'Strict-Transport-Security',
        'Trailer',
        'Transfer-Encoding',
        'Upgrade',
        'Vary',
        'Via',
        'Warning',
        'WWW-Authenticate',
        'X-Frame-Options',
        'X-UA-Compatible',
        'X-Content-Duration',
        'X-Content-Type-Options'
      ]
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

    def interesting_headers
      req = create_request('/')
      headers = []
      req.on_complete do |resp|
        resp.headers.each do |header|
          headers.push(header) unless common_resp_headers.include?(header[0])
        end
      end

      req.run
      headers
    end
end
