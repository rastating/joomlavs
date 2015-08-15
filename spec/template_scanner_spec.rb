require 'spec_helper'

describe TemplateScanner do

  let(:target_uri) { 'http://localhost/' }
  let(:opts_user_agent) { 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0' }

  before :each do
    @scanner = TemplateScanner.new(target_uri, {
      :user_agent => opts_user_agent,
    })
  end

  describe '#possible_paths' do
    it 'returns two possible paths for the template to be found' do
      expect(@scanner.possible_paths('test').length).to eq 2
    end
  end

  describe '#queue_requests' do
    context 'when passed a valid path index' do
      it 'queues a request to be made by hydra' do
        @scanner.queue_requests('foo', 0)
        @scanner.queue_requests('bar', 1)
        expect(@scanner.hydra.queued_requests.length).to eq 2
      end
    end

    context 'when passed an invalid path index' do
      it 'does not queue the request' do
        @scanner.queue_requests('foo', 3)
        @scanner.queue_requests('bar', 4)
        expect(@scanner.hydra.queued_requests.length).to eq 0
      end
    end
  end
end