require_relative '../lib/scanner'
require_relative '../lib/module_scanner'

RSpec.configure do |config|
  config.before :each do
    Typhoeus::Expectation.clear
  end
end