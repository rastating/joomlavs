require_relative '../lib/scanner'
require_relative '../lib/module_scanner'
require_relative '../lib/fingerprint_scanner'
require_relative '../lib/component_scanner'
require_relative '../lib/extension_scanner'
require_relative '../lib/template_scanner'

RSpec.configure do |config|
  config.before :each do
    Typhoeus::Expectation.clear
  end
end