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

describe ComponentScanner do
  let(:target_uri) { 'http://localhost/' }
  let(:opts_user_agent) { 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0' }

  let(:typhoeus_code) { 200 }
  let(:typhoeus_body) { '' }
  let(:typhoeus_headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }

  before :each do
    @scanner = ComponentScanner.new(
      target_uri,
      user_agent: opts_user_agent,
      threads: 20
    )

    Typhoeus.stub(/.*/) do
      Typhoeus::Response.new(code: typhoeus_code, body: typhoeus_body, headers: typhoeus_headers)
    end
  end

  describe '#possible_paths' do
    it 'returns two possible paths for the component to be found' do
      expect(@scanner.possible_paths('test').length).to eq 2
    end
  end

  describe '#extract_list_from_admin_index' do
    let(:typhoeus_body) { 'Index of page com_foo<br /> com_bar' }
    it 'returns a list of the component names, minus the com_ prefix' do
      res = @scanner.extract_list_from_admin_index
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_list_from_index' do
    let(:typhoeus_body) { 'Index of page com_foo<br /> com_bar' }
    it 'returns a list of the component names, minus the com_ prefix' do
      res = @scanner.extract_list_from_index
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_list_from_home' do
    let(:typhoeus_body) { 'Index of page com_foo<br /> com_bar' }
    it 'returns a list of the component names, minus the com_ prefix' do
      res = @scanner.extract_list_from_home
      expect(res).to eq ['foo', 'bar']
    end
  end
end
