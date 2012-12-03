require File.dirname(__FILE__) + '/lib/version'

module HappyMapper
  def self.show_version_changes(version)
    date = ""
    changes = []
    grab_changes = false

    File.open("#{File.dirname(__FILE__)}/CHANGELOG.md",'r') do |file|
      while (line = file.gets) do

        if line =~ /^##\s*#{version.gsub('.','\.')}\s*\/\s*(.+)\s*$/
          grab_changes = true
          date = $1.strip
        elsif line =~ /^##\s*.+$/
          grab_changes = false
        elsif grab_changes
          changes = changes << line
        end

      end
    end

    { :date => date, :changes => changes }
  end
end

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
  s.date = %q{2012-10-29}
  s.description = %q{Object to XML Mapping Library, using Nokogiri (fork from John Nunemaker's Happymapper)}
  s.extra_rdoc_files = [
    "README.md",
    "CHANGELOG.md",
    "TODO"
  ]
  s.files = `git ls-files -- lib/*`.split("\n")
  s.homepage = %q{http://github.com/dam5s/happymapper}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.1}
  s.summary = %q{Provides a simple way to map XML to Ruby Objects and back again.}
  s.license = "MIT"
  s.test_files = `git ls-files -- spec/*`.split("\n")


  changes = HappyMapper.show_version_changes(::HappyMapper::VERSION)

  s.post_install_message = %{
  Thank you for installing #{s.name} #{::HappyMapper::VERSION} / #{changes[:date]}.

  Changes:
  #{changes[:changes].collect{|change| "  #{change}"}.join("")}

}
  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, "~> 1.5" )
      s.add_development_dependency(%q<rspec>, ["~> 2.8"])
    else
      s.add_dependency(%q<nokogiri>, "~> 1.5" )
      s.add_dependency(%q<rspec>, ["~> 2.8"])
    end
  else
    s.add_dependency(%q<nokogiri>, "~> 1.5" )
    s.add_dependency(%q<rspec>, ["~> 2.8"])
  end
end

