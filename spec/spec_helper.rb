# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  cover "lib/**/*.rb"
  skip "lib/happymapper/version.rb"
  enable_coverage :branch
end

require "rspec"

require "nokogiri-happymapper"

def fixture_file(filename)
  File.read(File.dirname(__FILE__) + "/fixtures/#{filename}")
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = "spec/examples.txt"
end
