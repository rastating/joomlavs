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

require_relative 'scanner'

# This class provides functionality to scan for
# information to help fingerprint the Joomla website
class FingerprintScanner < Scanner
  def initialize(target_uri, opts)
    super(target_uri, opts)
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

  def registration_uri
    '/index.php?option=com_users&view=registration'
  end

  def directory_listing_enabled(uri)
    req = create_request(uri)
    enabled = false
    req.on_complete do |resp|
      if resp.code == 200 && resp.body[%r{<title>Index of}]
        enabled = true
      end
    end

    req.run
    enabled
  end

  def administrator_components_listing_enabled
    directory_listing_enabled('/administrator/components/')
  end

  def components_listing_enabled
    directory_listing_enabled('/components/')
  end

  def administrator_modules_listing_enabled
    directory_listing_enabled('/administrator/modules/')
  end

  def modules_listing_enabled
    directory_listing_enabled('/modules/')
  end

  def user_registration_enabled
    # Follow location option must be set to false to detect the
    # redirect to the login page if registration is disabled.
    req = create_request(registration_uri)
    req.options['followlocation'] = false

    enabled = true
    req.on_complete do |resp|
      enabled = resp.code == 200
    end

    req.run
    enabled
  end

  def version_from_readme
    req = create_request('/README.txt')
    version = nil
    req.on_complete do |resp|
      match = /(Joomla!?\s)([0-9]+(\.?[0-9]+)?(\.?[0-9]+)?)+\s/.match(resp.body)
      version = match.captures[1] if match
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
