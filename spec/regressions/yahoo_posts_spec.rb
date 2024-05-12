# frozen_string_literal: true

require "spec_helper"

RSpec.describe "parsing a yahoo posts xml" do
  before do
    post_klass = Class.new do
      include HappyMapper

      attribute :href, String
      attribute :hash, String
      attribute :description, String
      attribute :tag, String
      attribute :time, Time
      attribute :others, Integer
      attribute :extended, String
    end
    stub_const "Post", post_klass
  end

  it "parses xml attributes into ruby objects" do
    posts = Post.parse(fixture_file("posts.xml"))

    aggregate_failures do
      expect(posts.size).to eq(20)
      first = posts.first
      expect(first.href).to eq("http://roxml.rubyforge.org/")
      expect(first.hash).to eq("19bba2ab667be03a19f67fb67dc56917")
      expect(first.description).to eq("ROXML - Ruby Object to XML Mapping Library")
      expect(first.tag).to eq("ruby xml gems mapping")
      expect(first.time).to eq(Time.utc(2008, 8, 9, 5, 24, 20))
      expect(first.others).to eq(56)
      expect(first.extended)
        .to eq("ROXML is a Ruby library designed to make it easier for Ruby" \
               " developers to work with XML. Using simple annotations, it enables" \
               " Ruby classes to be custom-mapped to XML. ROXML takes care of the" \
               " marshalling and unmarshalling of mapped attributes so that developers" \
               " can focus on building first-class Ruby classes.")
    end
  end
end
