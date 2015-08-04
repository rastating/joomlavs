require 'spec_helper'

describe ModuleScanner do

  let(:target_uri) { 'http://localhost/' }
  let(:opts_user_agent) { 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0' }

  before :each do
    @scanner = ModuleScanner.new(target_uri, {
      :user_agent => opts_user_agent,
    })
  end

  describe '#possible_paths' do
    it 'returns two possible paths for the component to be found' do
      expect(@scanner.possible_paths('test').length).to eq 2
    end
  end
end