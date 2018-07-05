# frozen_string_literal: true

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

require 'coveralls'
Coveralls.wear!

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
