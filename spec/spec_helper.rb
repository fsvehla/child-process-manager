require 'rspec'
require 'mocha'

ROOT = File.expand_path('../..', __FILE__)

$: << "#{ ROOT }/lib"

RSpec.configure do |config|
  config.mock_with(:mocha)
end
