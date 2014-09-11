# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'happymapper/version'

Gem::Specification.new do |s|
  s.name = %q{nokogiri-happymapper}
  s.version = ::HappyMapper::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Damien Le Berrigaud",
    "John Nunemaker",
    "David Bolton",
    "Roland Swingler",
    "Etienne Vallette d'Osia",
    "Franklin Webber"]

  s.email = 'franklin.webber@gmail.com'
  s.date = %q{2014-02-18}
  s.description = %q{Object to XML Mapping Library, using Nokogiri (fork from John Nunemaker's Happymapper)}
  s.extra_rdoc_files = [ "README.md", "CHANGELOG.md" ]
  s.files = `git ls-files -- lib/*`.split("\n")
  s.homepage = %q{http://github.com/dam5s/happymapper}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.1}
  s.summary = %q{Provides a simple way to map XML to Ruby Objects and back again.}
  s.license = "MIT"
  s.test_files = `git ls-files -- spec/*`.split("\n")

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency 'nokogiri', '~> 1.5.0'
      s.add_development_dependency 'rspec', '~> 2.8'
      s.add_development_dependency 'rake'
      s.add_development_dependency 'rb-fsevent', '~> 0.9'
      s.add_development_dependency 'guard-rspec' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('1.9.2')
    else
        s.add_dependency(%q<nokogiri>, "~> 1.5.0" )
      s.add_dependency(%q<rspec>, ["~> 2.8"])
    end
  else
      s.add_dependency(%q<nokogiri>, "~> 1.5.0" )
    s.add_dependency(%q<rspec>, ["~> 2.8"])
  end
end
