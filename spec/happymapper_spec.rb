# frozen_string_literal: true

require "spec_helper"

class Country
  include HappyMapper

  attribute :code, String
  content :name, String
end

class State
  include HappyMapper
end

class Address
  include HappyMapper

  attr_accessor :xml_value, :xml_content

  tag "address"
  element :street, String
  element :postcode, String
  element :housenumber, String
  element :city, String
  has_one :country, Country
  has_one :state, State
end

class Feature
  include HappyMapper

  element :name, String, xpath: ".//text()"
end

class FeatureBullet
  include HappyMapper

  tag "features_bullets"
  has_many :features, Feature
  element :bug, String
end

class Product
  include HappyMapper

  element :title, String
  has_one :feature_bullets, FeatureBullet
  has_one :address, Address
end

class Rate
  include HappyMapper
end

class Place
  include HappyMapper

  element :name, String
end

class Radar
  include HappyMapper

  has_many :places, Place, tag: :place
end

module QuarterTest
  class Quarter
    include HappyMapper

    element :start, String
  end

  class Details
    include HappyMapper

    element :round, Integer
    element :quarter, Integer
  end

  class Game
    include HappyMapper

    # in an ideal world, the following elements would all be
    # called 'quarter' with an attribute indicating which quarter
    # it represented, but the refactoring that allows a single class
    # to be used for all these differently named elements is the next
    # best thing
    has_one :details, QuarterTest::Details
    has_one :q1, QuarterTest::Quarter, tag: "q1"
    has_one :q2, QuarterTest::Quarter, tag: "q2"
    has_one :q3, QuarterTest::Quarter, tag: "q3"
    has_one :q4, QuarterTest::Quarter, tag: "q4"
  end
end

# To check for multiple primitives
class Artist
  include HappyMapper

  tag "artist"
  element :images, String, tag: "image", single: false
  element :name, String
end

# Testing the XmlContent type
module Dictionary
  class Variant
    include HappyMapper

    tag "var"
    has_xml_content

    def to_html
      xml_content.gsub("<tag>", "<em>").gsub("</tag>", "</em>")
    end
  end

  class Definition
    include HappyMapper

    tag "def"
    element :text, XmlContent, tag: "dtext"
  end

  class Record
    include HappyMapper

    tag "record"
    has_many :definitions, Definition
    has_many :variants, Variant, tag: "var"
  end
end

module AmbiguousItems
  class Item
    include HappyMapper

    tag "item"
    element :name, String
    element :item, String
  end
end

class PublishOptions
  include HappyMapper

  tag "publishOptions"

  element :author, String, tag: "author"

  element :draft, Boolean, tag: "draft"
  element :scheduled_day, String, tag: "scheduledDay"
  element :scheduled_time, String, tag: "scheduledTime"
  element :published_day, String, tag: "publishDisplayDay"
  element :published_time, String, tag: "publishDisplayTime"
  element :created_day, String, tag: "publishDisplayDay"
  element :created_time, String, tag: "publishDisplayTime"
end

class Article
  include HappyMapper

  tag "Article"
  namespace "article"

  attr_writer :xml_value

  element :title, String
  element :text, String
  has_many :photos, "Photo", tag: "Photo", namespace: "photo", xpath: "/article:Article"
  has_many :galleries, "Gallery", tag: "Gallery", namespace: "gallery"

  element :publish_options, PublishOptions, tag: "publishOptions", namespace: "article"
end

class PartiallyBadArticle
  include HappyMapper

  attr_writer :xml_value

  tag "Article"
  namespace "article"

  element :title, String
  element :text, String
  has_many :photos, "Photo", tag: "Photo", namespace: "photo", xpath: "/article:Article"
  has_many :videos, "Video", tag: "Video", namespace: "video"

  element :publish_options, PublishOptions, tag: "publishOptions", namespace: "article"
end

class Photo
  include HappyMapper

  tag "Photo"
  namespace "photo"

  attr_writer :xml_value

  element :title, String
  element :publish_options, PublishOptions, tag: "publishOptions", namespace: "photo"
end

class Gallery
  include HappyMapper

  tag "Gallery"
  namespace "gallery"

  attr_writer :xml_value

  element :title, String
end

class Video
  include HappyMapper

  tag "Video"
  namespace "video"

  attr_writer :xml_value

  element :title, String
  element :publish_options, PublishOptions, tag: "publishOptions", namespace: "video"
end

class DefaultNamespaceCombi
  include HappyMapper

  register_namespace "bk", "urn:loc.gov:books"
  register_namespace "isbn", "urn:ISBN:0-395-36341-6"
  register_namespace "p", "urn:loc.gov:people"
  namespace "bk"

  tag "book"

  element :title, String, namespace: "bk", tag: "title"
  element :number, String, namespace: "isbn", tag: "number"
  element :author, String, namespace: "p", tag: "author"
end

module StringFoo
  class Bar
    include HappyMapper

    has_many :things, "StringFoo::Thing"
  end

  class Thing
    include HappyMapper
  end
end

describe HappyMapper do
  describe "being included into another class" do
    let(:klass) do
      Class.new { include HappyMapper }
    end
    let(:nested_klass) do
      Class.new { include HappyMapper }
    end

    it "sets attributes to an array" do
      expect(klass.attributes).to eq([])
    end

    it "sets @elements to a hash" do
      expect(klass.elements).to eq([])
    end

    it "allows adding an attribute" do
      expect do
        klass.attribute :name, String
      end.to change(klass, :attributes)
    end

    it "allows adding an attribute containing a dash" do
      expect do
        klass.attribute :"bar-baz", String
      end.to change(klass, :attributes)
    end

    it "is able to get all attributes in array" do
      klass.attribute :name, String
      expect(klass.attributes.size).to eq(1)
    end

    it "allows adding an element" do
      expect do
        klass.element :name, String
      end.to change(klass, :elements)
    end

    it "allows adding an element containing a dash" do
      expect do
        klass.element :"bar-baz", String
      end.to change(klass, :elements)
    end

    it "is able to get all elements in array" do
      klass.element(:name, String)
      expect(klass.elements.size).to eq(1)
    end

    it "allows has one association" do
      klass.has_one(:user, nested_klass)
      element = klass.elements.first

      aggregate_failures do
        expect(element.name).to eq("user")
        expect(element.type).to eq(nested_klass)
        expect(element.options[:single]).to be(true)
      end
    end

    it "allows has many association" do
      klass.has_many(:users, nested_klass)
      element = klass.elements.first

      aggregate_failures do
        expect(element.name).to eq("users")
        expect(element.type).to eq(nested_klass)
        expect(element.options[:single]).to be(false)
      end
    end

    it "defaults tag name to lowercase class name" do
      named = Class.new { include HappyMapper }
      allow(named).to receive(:name).and_return "Boo"

      expect(named.tag_name).to eq("boo")
    end

    it "generates no tag name for anonymous class" do
      anon = Class.new { include HappyMapper }
      expect(anon.tag_name).to be_nil
    end

    it "defaults tag name of class in modules to the last constant lowercase" do
      nested_named = Class.new { include HappyMapper }
      allow(nested_named).to receive(:name).and_return "Bar::Baz"
      expect(nested_named.tag_name).to eq("baz")
    end

    it "allows setting tag name" do
      klass.tag("FooBar")
      expect(klass.tag_name).to eq("FooBar")
    end

    it "allows setting a namespace" do
      klass.namespace(namespace = "boo")
      expect(klass.namespace).to eq(namespace)
    end

    it "provides #parse" do
      expect(klass).to respond_to(:parse)
    end
  end

  describe "#attributes" do
    let(:foo_klass) do
      Class.new do
        include HappyMapper

        attribute :foo, String
        attribute :bar, String
      end
    end
    let(:bar_klass) do
      Class.new do
        include HappyMapper

        attribute :baz1, String
        attribute :baz2, String
        attribute :baz3, String
        attribute :baz4, String
      end
    end

    it "returns only attributes for the current class" do
      aggregate_failures do
        expect(foo_klass.attributes.size).to eq 2
        expect(bar_klass.attributes.size).to eq 4
      end
    end
  end

  describe "#elements" do
    let(:foo_klass) do
      Class.new do
        include HappyMapper

        element :foo, String
      end
    end
    let(:bar_klass) do
      Class.new do
        include HappyMapper

        element :baz1, String
        element :baz2, String
      end
    end

    it "returns only elements for the current class" do
      aggregate_failures do
        expect(foo_klass.elements.size).to eq 1
        expect(bar_klass.elements.size).to eq 2
      end
    end
  end

  describe "#content" do
    it "takes String as default argument for type" do
      State.content :name
      address = Address.parse(fixture_file("address.xml"))
      name = address.state.name

      aggregate_failures do
        expect(name).to eq "Lower Saxony"
        expect(name).to be_a String
      end
    end

    it "works when specific type is provided" do
      Rate.content :value, Float
      Product.has_one :rate, Rate
      product = Product.parse(fixture_file("product_default_namespace.xml"), single: true)
      value = product.rate.value

      aggregate_failures do
        expect(value).to eq(120.25)
        expect(value).to be_a Float
      end
    end
  end

  it "parses xml containing the desired element as root node" do
    address = Address.parse(fixture_file("address.xml"), single: true)

    aggregate_failures do
      expect(address.street).to eq("Milchstrasse")
      expect(address.postcode).to eq("26131")
      expect(address.housenumber).to eq("23")
      expect(address.city).to eq("Oldenburg")
      expect(address.country.class).to eq(Country)
    end
  end

  it "parses text node correctly" do
    address = Address.parse(fixture_file("address.xml"), single: true)

    aggregate_failures do
      expect(address.country.name).to eq("Germany")
      expect(address.country.code).to eq("de")
    end
  end

  it "treats Nokogiri::XML::Document as root" do
    doc = Nokogiri::XML(fixture_file("address.xml"))
    address = Address.parse(doc)
    expect(address.class).to eq(Address)
  end

  it "returns nil rather than empty array for absent values when :single => true" do
    address = Address.parse('<?xml version="1.0" encoding="UTF-8"?><foo/>', single: true)
    expect(address).to be_nil
  end

  it "ignores :in_groups_of when :single is true" do
    addr1 = Address.parse('<?xml version="1.0" encoding="UTF-8"?><foo/>', single: true)
    addr2 = Address.parse('<?xml version="1.0" encoding="UTF-8"?><foo/>', single: true,
                                                                          in_groups_of: 10)
    expect(addr1).to eq(addr2)
  end

  it "parses xml with nested elements" do
    radars = Radar.parse(fixture_file("radar.xml"))

    aggregate_failures do
      first = radars[0]
      expect(first.places.size).to eq(1)
      expect(first.places[0].name).to eq("Store")
      second = radars[1]
      expect(second.places.size).to eq(0)
      third = radars[2]
      expect(third.places.size).to eq(2)
      expect(third.places[0].name).to eq("Work")
      expect(third.places[1].name).to eq("Home")
    end
  end

  it "parses xml with element name different to class name" do
    game = QuarterTest::Game.parse(fixture_file("quarters.xml"))

    aggregate_failures do
      expect(game.q1.start).to eq("4:40:15 PM")
      expect(game.q2.start).to eq("5:18:53 PM")
    end
  end

  it "parses xml with no namespace" do
    product = Product.parse(fixture_file("product_no_namespace.xml"), single: true)

    aggregate_failures do
      expect(product.title).to eq("A Title")
      expect(product.feature_bullets.bug).to eq("This is a bug")
      expect(product.feature_bullets.features.size).to eq(2)
      expect(product.feature_bullets.features[0].name).to eq("This is feature text 1")
      expect(product.feature_bullets.features[1].name).to eq("This is feature text 2")
    end
  end

  it "parses xml with default namespace" do
    product = Product.parse(fixture_file("product_default_namespace.xml"), single: true)

    aggregate_failures do
      expect(product.title).to eq("A Title")
      expect(product.feature_bullets.bug).to eq("This is a bug")
      expect(product.feature_bullets.features.size).to eq(2)
      expect(product.feature_bullets.features[0].name).to eq("This is feature text 1")
      expect(product.feature_bullets.features[1].name).to eq("This is feature text 2")
    end
  end

  it "parses xml with single namespace" do
    product = Product.parse(fixture_file("product_single_namespace.xml"), single: true)

    aggregate_failures do
      expect(product.title).to eq("A Title")
      expect(product.feature_bullets.bug).to eq("This is a bug")
      expect(product.feature_bullets.features.size).to eq(2)
      expect(product.feature_bullets.features[0].name).to eq("This is feature text 1")
      expect(product.feature_bullets.features[1].name).to eq("This is feature text 2")
    end
  end

  it "allows speficying child element class with a string" do
    bar = StringFoo::Bar.parse "<bar><thing/></bar>"

    expect(bar.things).to contain_exactly(StringFoo::Thing)
  end

  it "parses multiple images" do
    artist = Artist.parse(fixture_file("multiple_primitives.xml"))

    aggregate_failures do
      expect(artist.name).to eq("value")
      expect(artist.images.size).to eq(2)
    end
  end

  describe "Default namespace combi" do
    let(:file_contents) { fixture_file("default_namespace_combi.xml") }
    let(:book) { DefaultNamespaceCombi.parse(file_contents, single: true) }

    it "parses author" do
      expect(book.author).to eq("Frank Gilbreth")
    end

    it "parses title" do
      expect(book.title).to eq("Cheaper by the Dozen")
    end

    it "parses number" do
      expect(book.number).to eq("1568491379")
    end
  end

  describe "Xml Content" do
    let(:records) { Dictionary::Record.parse fixture_file("dictionary.xml") }

    it "parses XmlContent" do
      expect(records.first.definitions.first.text)
        .to eq("a large common parrot, <bn>Cacatua galerita</bn>, predominantly" \
               " white, with yellow on the undersides of wings and tail and a" \
               " forward curving yellow crest, found in Australia, New Guinea" \
               " and nearby islands.")
    end

    it "saves object's xml content" do
      aggregate_failures do
        expect(records.first.variants.first.xml_content).to eq "white <tag>cockatoo</tag>"
        expect(records.first.variants.last.to_html).to eq "<em>white</em> cockatoo"
      end
    end
  end

  it "parses ambiguous items" do
    items = AmbiguousItems::Item.parse(fixture_file("ambiguous_items.xml"),
                                       xpath: "/ambiguous/my-items")
    expect(items.map(&:name)).to eq(%w(first second third).map { |s| "My #{s} item" })
  end

  context Article do
    let(:article) { Article.parse(fixture_file("subclass_namespace.xml")) }

    it "parses the publish options for Article and Photo" do
      aggregate_failures do
        expect(article.title).not_to be_nil
        expect(article.text).not_to be_nil
        expect(article.photos).not_to be_nil
        expect(article.photos.first.title).not_to be_nil
      end
    end

    it "parses the publish options for Article" do
      expect(article.publish_options).not_to be_nil
    end

    it "parses the publish options for Photo" do
      expect(article.photos.first.publish_options).not_to be_nil
    end

    it "onlies find only items at the parent level" do
      expect(article.photos.length).to eq(1)
    end
  end

  describe "Namespace is missing because an optional element that uses it is not present" do
    it "parses successfully" do
      article = PartiallyBadArticle.parse(fixture_file("subclass_namespace.xml"))

      aggregate_failures do
        expect(article).not_to be_nil
        expect(article.title).not_to be_nil
        expect(article.text).not_to be_nil
        expect(article.photos).not_to be_nil
        expect(article.photos.first.title).not_to be_nil
      end
    end
  end

  describe "with limit option" do
    let(:post_klass) do
      Class.new do
        include HappyMapper

        tag "post"
      end
    end

    it "returns results with limited size: 6" do
      sizes = []
      post_klass.parse(fixture_file("posts.xml"), in_groups_of: 6) do |a|
        sizes << a.size
      end
      expect(sizes).to eq([6, 6, 6, 2])
    end

    it "returns results with limited size: 10" do
      sizes = []
      post_klass.parse(fixture_file("posts.xml"), in_groups_of: 10) do |a|
        sizes << a.size
      end
      expect(sizes).to eq([10, 10])
    end
  end

  context "when letting user set Nokogiri::XML::ParseOptions" do
    let(:default) do
      Class.new do
        include HappyMapper

        element :item, String
      end
    end
    let(:custom) do
      Class.new do
        include HappyMapper

        element :item, String
        with_nokogiri_config(&:default_xml)
      end
    end

    it "initializes @nokogiri_config_callback to nil" do
      expect(default.nokogiri_config_callback).to be_nil
    end

    it "defaults to Nokogiri::XML::ParseOptions::STRICT" do
      expect { default.parse(fixture_file("set_config_options.xml")) }
        .to raise_error(Nokogiri::XML::SyntaxError)
    end

    it "accepts .on_config callback" do
      expect(custom.nokogiri_config_callback).not_to be_nil
    end

    it "parses according to @nokogiri_config_callback" do
      expect { custom.parse(fixture_file("set_config_options.xml")) }.not_to raise_error
    end

    it "can clear @nokogiri_config_callback" do
      custom.with_nokogiri_config { nil }
      expect { custom.parse(fixture_file("set_config_options.xml")) }
        .to raise_error(Nokogiri::XML::SyntaxError)
    end
  end

  describe "#xml_value" do
    it "does not reformat the xml" do
      xml = fixture_file("unformatted_address.xml")
      address = Address.parse(xml, single: true)

      expect(address.xml_value)
        .to eq "<address><street>Milchstrasse</street>" \
               "<housenumber>23</housenumber></address>"
    end
  end

  describe "#xml_content" do
    it "does not reformat the xml" do
      xml = fixture_file("unformatted_address.xml")
      address = Address.parse(xml)

      expect(address.xml_content)
        .to eq "<street>Milchstrasse</street><housenumber>23</housenumber>"
    end
  end

  describe "#to_xml" do
    let(:original) { "<foo><bar>baz</bar></foo>" }
    let(:parsed) { described_class.parse original }

    it "has UTF-8 encoding by default" do
      aggregate_failures do
        expect(original.encoding).to eq Encoding::UTF_8
        expect(parsed.to_xml.encoding).to eq Encoding::UTF_8
      end
    end
  end
end
