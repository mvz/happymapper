require 'rspec'

require File.join(File.dirname(__FILE__), '..', 'lib', 'happymapper')

def fixture_file(filename)
  File.read(File.dirname(__FILE__) + "/fixtures/#{filename}")
end
