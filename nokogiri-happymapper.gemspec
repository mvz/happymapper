# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib/happymapper/version.rb')

Gem::Specification.new do |s|
  s.name = 'nokogiri-happymapper'
  s.version = ::HappyMapper::VERSION

  s.authors = [
    'Damien Le Berrigaud',
    'John Nunemaker',
    'David Bolton',
    'Roland Swingler',
    "Etienne Vallette d'Osia",
    'Franklin Webber',
    'Matijs van Zuijlen'
  ]

  s.email = 'matijs@matijs.net'
  s.description = "Object to XML Mapping Library, using Nokogiri (fork from John Nunemaker's Happymapper)"
  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md', 'License']
  s.files = `git ls-files -- lib/*`.split("\n")
  s.homepage = 'http://github.com/mvz/happymapper'
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.4.0'
  s.summary = 'Provides a simple way to map XML to Ruby Objects and back again.'
  s.license = 'MIT'
  s.test_files = `git ls-files -- spec/*`.split("\n")

  s.add_runtime_dependency('nokogiri', '~> 1.5')

  s.add_development_dependency('rake', '~> 13.0')
  s.add_development_dependency('rspec', ['~> 3.0'])
  s.add_development_dependency('rubocop', '~> 0.91.0')
  s.add_development_dependency('rubocop-performance', ['~> 1.8.0'])
  s.add_development_dependency('rubocop-rspec', '~> 1.43.1')
  s.add_development_dependency('simplecov', ['>= 0.18.0', '< 0.20.0'])
end
