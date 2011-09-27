require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "nokogiri-happymapper"
    gem.summary = %Q{Provides a simple way to map XML to Ruby Objects}
    gem.description = "Object to XML Mapping Library, using Nokogiri (fork from John Nunemaker's Happymapper)"
    gem.email = "damien@meliondesign.com"
    gem.homepage = "http://github.com/dam5s/happymapper"
    gem.authors = ["Damien Le Berrigaud", "John Nunemaker", "David Bolton", "Roland Swingler", "Etienne Vallette d'Osia"]
    gem.add_dependency "nokogiri", "~> 1.4.2"
    gem.add_development_dependency "rspec", "~> 2.0"
    gem.files = FileList['lib/**/*.rb']
    gem.test_files = FileList['spec/**/*']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = '-c --format d'
end

task :spec
task :default => :spec