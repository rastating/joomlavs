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

require 'typhoeus'

# This class provides the base functionality
# for all the scanner classes.
class Scanner
  def initialize(target_uri, opts)
    update_target_uri target_uri
    @opts = opts
    @hydra = Typhoeus::Hydra.new(max_concurrency: opts[:threads])
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
    @opts[:follow_redirection]
  end

  def normalize_uri(*parts)
    uri = parts * '/'
    uri = uri.gsub!('//', '/') while uri.index('//')

    # Makes sure there's a starting slash
    unless uri[0, 1] == '/'
      uri = '/' + uri
    end

    uri
  end

  def create_request(path)
    req = Typhoeus::Request.new(
      target_uri + path,
      followlocation: @opts[:follow_redirection] ? true : false,
      headers: { 'User-Agent' => @opts[:user_agent] }
    )
    req.options['userpwd'] = @opts[:basic_auth] if @opts[:basic_auth]
    req.options['proxy'] = @opts[:proxy] if @opts[:proxy]
    req.options['proxyuserpwd'] = @opts[:proxy_auth] if @opts[:proxy_auth]
    req
  end

  def index_request
    create_request('/')
  end

  def run_request(req)
    req.on_complete do |resp|
      return resp
    end

    req.run
  end

  def target_redirects_to
    req = create_request('/')
    req.options['followlocation'] = false
    loc = nil
    resp = run_request(req)

    if resp.code == 301 || resp.code == 302
      loc = resp.headers['location']
    end

    loc
  end

  def extract_version_number(text)
    match = /([0-9]+(\.?[0-9]+)?(\.?[0-9]+)?)+/.match(text)
    return match.captures[0] if match
  end
end
