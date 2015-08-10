require 'spec_helper'

describe FingerprintScanner do
  let(:target_uri) { 'http://localhost/' }
  let(:opts_user_agent) { 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0' }
  let(:opts_threads) { 20 }

  let(:typhoeus_code) { 200 }
  let(:typhoeus_body) { '' }
  let(:typhoeus_headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }

  before :each do
    @scanner = FingerprintScanner.new(target_uri, {
      :user_agent => opts_user_agent,
      :threads => opts_threads
    })

    Typhoeus.stub(/.*/) do
      Typhoeus::Response.new(code: typhoeus_code, body: typhoeus_body, headers: typhoeus_headers)
    end
  end

  describe '#version_from_readme' do
    context 'when a valid version number is in the README.txt file' do
      let(:typhoeus_body) { '* Joomla! 3.4 version history - https://docs.joomla.org/Joomla_3.4_version_history' }
      it 'returns the version number from the file' do
        expect(@scanner.version_from_readme).to eq '3.4'
      end
    end

    context 'when no version number appears in the README.txt file' do
      let(:typhoeus_body) { 'This is not the readme you are looking for.' }
      it 'returns nil' do
        expect(@scanner.version_from_readme).to be_nil
      end
    end
  end

  describe '#user_registration_enabled' do
    context 'when the response code is 200' do
      let(:typhoeus_code) { 200 }
      it 'returns true' do
        expect(@scanner.user_registration_enabled).to eq true
      end
    end

    context 'when the response code != 200' do
      let(:typhoeus_code) { 301 }
      it 'returns false' do
        expect(@scanner.user_registration_enabled).to eq false
      end
    end
  end

  describe '#directory_listing_enabled' do
    context 'when the served page doesn\'t have a title starting with "Index of"' do
      let(:typhoeus_code) { 200 }
      let(:typhoeus_body) { '<html><head><title>Not the index you are looking for</title></head><body /></html>' }
      it 'returns false' do
        expect(@scanner.directory_listing_enabled('/secret/')).to eq false
      end
    end

    context 'when the served page has a title starting with "Index of"' do
      let(:typhoeus_code) { 200 }
      let(:typhoeus_body) { '<html><head><title>Index of secret</title></head><body /></html>' }
      it 'returns true' do
        expect(@scanner.directory_listing_enabled('/secret/')).to eq true
      end
    end

    context 'when the response code != 200' do
      let(:typhoeus_code) { 404 }
      it 'returns false' do
        expect(@scanner.directory_listing_enabled('/secret/')).to eq false
      end
    end
  end
end