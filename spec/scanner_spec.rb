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

require 'spec_helper'

describe Scanner do

  let(:target_uri) { 'http://localhost/' }
  let(:opts_user_agent) { 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0' }
  let(:opts_threads) { 20 }
  let(:opts_follow_redirection) { nil }
  let(:opts_basic_auth) { nil }
  let(:opts_proxy) { nil }
  let(:opts_proxy_auth) { nil }

  let(:typhoeus_code) { 200 }
  let(:typhoeus_body) { '' }
  let(:typhoeus_headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }

  before :each do
    @scanner = Scanner.new(target_uri, {
      :user_agent => opts_user_agent,
      :threads => opts_threads,
      :follow_redirection => opts_follow_redirection,
      :basic_auth => opts_basic_auth,
      :proxy => opts_proxy,
      :proxy_auth => opts_proxy_auth
    })

    Typhoeus.stub(/.*/) do
      Typhoeus::Response.new(code: typhoeus_code, body: typhoeus_body, headers: typhoeus_headers)
    end
  end

  describe '#new' do
    it 'takes two parameters and returns a Scanner object' do
      expect(@scanner).to be_an_instance_of Scanner
    end

    it 'sets the Hydra max_concurrency to the value of opts[:threads]' do
      expect(@scanner.hydra.max_concurrency).to eq opts_threads
    end
  end

  describe '#target_uri' do
    it 'has no trailing slash' do
      expect(@scanner.target_uri).not_to end_with '/'
    end
  end

  describe '#update_target_uri' do
    context 'when passed http://127.0.0.1/' do
      it 'sets the target_uri to http://127.0.0.1' do
        @scanner.update_target_uri 'http://127.0.0.1/'
        expect(@scanner.target_uri).to eq 'http://127.0.0.1'
      end
    end

    context 'when passed 127.0.0.1' do
      it 'sets the target_uri to 127.0.0.1' do
        @scanner.update_target_uri '127.0.0.1'
        expect(@scanner.target_uri).to eq '127.0.0.1'
      end
    end
  end

  describe '#hydra' do
    it 'returns a Typhoeus::Hydra object' do
      expect(@scanner.hydra).to be_an_instance_of Typhoeus::Hydra
    end
  end

  describe '#follow_redirection' do
    context 'when the :follow_redirection option is not set' do
      let(:opts_follow_redirection) { nil }
      it 'returns nil' do
        expect(@scanner.follow_redirection).to be_nil
      end
    end

    context 'when the :follow_redirection option is set' do
      let(:opts_follow_redirection) { true }
      it 'equals the value of the :follow_redirection option' do
        expect(@scanner.follow_redirection).to eq true
      end
    end
  end

  describe '#normalize_uri' do
    it 'starts with a leading forward slash' do
      expect(@scanner.normalize_uri('path', 'to', 'normalize')).to start_with '/'
    end

    it 'joins each part specified with a forward slash' do
      expect(@scanner.normalize_uri('path', 'to', 'normalize')).to eq '/path/to/normalize'
    end
  end

  describe '#create_request' do
    it 'takes one parameter and return a Typhoeus::Request object' do
      expect(@scanner.create_request('/')).to be_an_instance_of Typhoeus::Request
    end

    it 'uses the value of target_uri for the base address' do
      expect(@scanner.create_request('/').url).to start_with @scanner.target_uri
    end

    it 'sets the value of the User-Agent header based on the :user_agent option' do
      expect(@scanner.create_request('/').options[:headers]['User-Agent']).to eq opts_user_agent
    end

    context 'when the :follow_redirection option is set' do
      let(:opts_follow_redirection) { true }
      it 'sets the followlocation option according to the options passed to #new' do
        expect(@scanner.create_request('/').options[:followlocation]).to eq true
      end
    end

    context 'when the :follow_redirection option is not set' do
      let(:opts_follow_redirection) { nil }
      it 'sets the followlocation option to false' do
        expect(@scanner.create_request('/').options[:followlocation]).to eq false
      end
    end

    context 'when the :basic_auth option is set' do
      let(:opts_basic_auth) { 'root:toor ' }
      it 'sets the userpwd option' do
        expect(@scanner.create_request('/').options['userpwd']).to eq opts_basic_auth
      end
    end

    context 'when the :proxy option is set' do
      let(:opts_proxy) { 'socks5://127.0.0.1:9150' }
      it 'sets the proxy option' do
        expect(@scanner.create_request('/').options['proxy']).to eq opts_proxy
      end
    end

    context 'when the :proxy_auth option is set' do
      let(:opts_proxy_auth) { 'root:toor' }
      it 'sets the proxyuserpwd option' do
        expect(@scanner.create_request('/').options['proxyuserpwd']).to eq opts_proxy_auth
      end
    end
  end

  describe '#target_redirects_to' do
    context 'when the response code is not 301 or 302' do
      let(:typhoeus_code) { 200 }
      it 'returns nil' do
        expect(@scanner.target_redirects_to).to be_nil
      end
    end

    context 'when the response code is 301' do
      let(:typhoeus_code) { 301 }
      let(:typhoeus_headers) { { 'Location' => 'http://redirected_location/' } }
      it 'returns the value of the location header when the response code is 301' do
        expect(@scanner.target_redirects_to).to eq 'http://redirected_location/'
      end
    end

    context 'when the response code is 302' do
      let(:typhoeus_code) { 302 }
      let(:typhoeus_headers) { { 'Location' => 'http://redirected_location/' } }
      it 'returns the value of the location header when the response code is 301' do
        expect(@scanner.target_redirects_to).to eq 'http://redirected_location/'
      end
    end
  end

  describe '#run_request' do
    it 'takes one parameter and returns a Typhoeus::Response object' do
      req = @scanner.create_request('/')
      expect(@scanner.run_request(req)).to be_an_instance_of Typhoeus::Response
    end
  end

  describe '#extract_version_number' do
    it 'returns a version number containing up to three numbers' do
      expect(@scanner.extract_version_number('1.2.1 Stable')).to eq '1.2.1'
    end

    it 'returns nil if no version number can be found' do
      expect(@scanner.extract_version_number('invalid version string')).to be_nil
    end

    it 'returns the version number excluding text based additions such as "-beta"' do
      expect(@scanner.extract_version_number('1.2.1-beta')).to eq '1.2.1'
    end
  end
end