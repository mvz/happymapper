# frozen_string_literal: true

require "spec_helper"
require "uri"

module Atom
  class Feed
    include HappyMapper
    tag "feed"

    attribute :xmlns, String, single: true
    element :id, String, single: true
    element :title, String, single: true
    element :updated, DateTime, single: true
    element :link, String, single: false, attributes: {
      rel: String,
      type: String,
      href: String
    }
    # has_many :entries, Entry # nothing interesting in the entries
  end
end

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

module FedEx
  class Address
    include HappyMapper

    tag "Address"
    namespace "v2"
    element :city, String, tag: "City"
    element :state, String, tag: "StateOrProvinceCode"
    element :zip, String, tag: "PostalCode"
    element :countrycode, String, tag: "CountryCode"
    element :residential, Boolean, tag: "Residential"
  end

  class Event
    include HappyMapper

    tag "Events"
    namespace "v2"
    element :timestamp, String, tag: "Timestamp"
    element :eventtype, String, tag: "EventType"
    element :eventdescription, String, tag: "EventDescription"
    has_one :address, Address
  end

  class PackageWeight
    include HappyMapper

    tag "PackageWeight"
    namespace "v2"
    element :units, String, tag: "Units"
    element :value, Integer, tag: "Value"
  end

  class TrackDetails
    include HappyMapper

    tag "TrackDetails"
    namespace "v2"
    element   :tracking_number, String, tag: "TrackingNumber"
    element   :status_code, String, tag: "StatusCode"
    element   :status_desc, String, tag: "StatusDescription"
    element   :carrier_code, String, tag: "CarrierCode"
    element   :service_info, String, tag: "ServiceInfo"
    has_one   :weight, PackageWeight, tag: "PackageWeight"
    element   :est_delivery, String, tag: "EstimatedDeliveryTimestamp"
    has_many  :events, Event
  end

  class Notification
    include HappyMapper

    tag "Notifications"
    namespace "v2"
    element :severity, String, tag: "Severity"
    element :source, String, tag: "Source"
    element :code, Integer, tag: "Code"
    element :message, String, tag: "Message"
    element :localized_message, String, tag: "LocalizedMessage"
  end

  class TransactionDetail
    include HappyMapper

    tag "TransactionDetail"
    namespace "v2"
    element :cust_tran_id, String, tag: "CustomerTransactionId"
  end

  class TrackReply
    include HappyMapper

    tag "TrackReply"
    namespace "v2"
    element   :highest_severity, String, tag: "HighestSeverity"
    element   :more_data, Boolean, tag: "MoreData"
    has_many  :notifications, Notification, tag: "Notifications"
    has_many  :trackdetails, TrackDetails, tag: "TrackDetails"
    has_one   :tran_detail, TransactionDetail, tab: "TransactionDetail"
  end
end

class Place
  include HappyMapper
  element :name, String
end

class Radar
  include HappyMapper
  has_many :places, Place, tag: :place
end

class Post
  include HappyMapper

  attribute :href, String
  attribute :hash, String
  attribute :description, String
  attribute :tag, String
  attribute :time, Time
  attribute :others, Integer
  attribute :extended, String
end

class User
  include HappyMapper

  element :id, Integer
  element :name, String
  element :screen_name, String
  element :location, String
  element :description, String
  element :profile_image_url, String
  element :url, String
  element :protected, Boolean
  element :followers_count, Integer
end

class Status
  include HappyMapper

  register_namespace "fake", "faka:namespace"

  element :id, Integer
  element :text, String
  element :created_at, Time
  element :source, String
  element :truncated, Boolean
  element :in_reply_to_status_id, Integer
  element :in_reply_to_user_id, Integer
  element :favorited, Boolean
  element :non_existent, String, tag: "dummy", namespace: "fake"
  has_one :user, User
end

class CurrentWeather
  include HappyMapper

  tag "ob"
  namespace "aws"
  element :temperature, Integer, tag: "temp"
  element :feels_like, Integer, tag: "feels-like"
  element :current_condition, String, tag: "current-condition", attributes: { icon: String }
end

# for type coercion
class ProductGroup < String; end

module PITA
  class Item
    include HappyMapper

    tag "Item" # if you put class in module you need tag
    element :asin, String, tag: "ASIN"
    element :detail_page_url, URI, tag: "DetailPageURL", parser: :parse
    element :manufacturer, String, tag: "Manufacturer", deep: true
    element :point, String, tag: "point", namespace: "georss"
    element :product_group, ProductGroup, tag: "ProductGroup", deep: true,
                                          parser: :new, raw: true
  end

  class Items
    include HappyMapper

    tag "Items" # if you put class in module you need tag
    element :total_results, Integer, tag: "TotalResults"
    element :total_pages, Integer, tag: "TotalPages"
    has_many :items, Item
  end
end

module GitHub
  class Commit
    include HappyMapper

    tag "commit"
    element :url, String
    element :tree, String
    element :message, String
    element :id, String
    element :"committed-date", Date
  end
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
      Class.new do
        include HappyMapper
      end
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
      klass.has_one(:user, User)
      element = klass.elements.first

      aggregate_failures do
        expect(element.name).to eq("user")
        expect(element.type).to eq(User)
        expect(element.options[:single]).to be(true)
      end
    end

    it "allows has many association" do
      klass.has_many(:users, User)
      element = klass.elements.first

      aggregate_failures do
        expect(element.name).to eq("users")
        expect(element.type).to eq(User)
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
    it "returns only attributes for the current class" do
      aggregate_failures do
        expect(Post.attributes.size).to eq(7)
        expect(Status.attributes.size).to eq(0)
      end
    end
  end

  describe "#elements" do
    it "returns only elements for the current class" do
      aggregate_failures do
        expect(Post.elements.size).to eq(0)
        expect(Status.elements.size).to eq(10)
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

  it "parses xml elements to ruby objcts" do
    statuses = Status.parse(fixture_file("statuses.xml"))

    aggregate_failures do
      expect(statuses.size).to eq(20)
      first = statuses.first
      expect(first.id).to eq(882_281_424)
      expect(first.created_at).to eq(Time.utc(2008, 8, 9, 5, 38, 12))
      expect(first.source).to eq("web")
      expect(first.truncated).to be_falsey
      expect(first.in_reply_to_status_id).to eq(1234)
      expect(first.in_reply_to_user_id).to eq(12_345)
      expect(first.favorited).to be_falsey
      expect(first.user.id).to eq(4243)
      expect(first.user.name).to eq("John Nunemaker")
      expect(first.user.screen_name).to eq("jnunemaker")
      expect(first.user.location).to eq("Mishawaka, IN, US")
      expect(first.user.description)
        .to eq "Loves his wife, ruby, notre dame football and iu basketball"
      expect(first.user.profile_image_url)
        .to eq("http://s3.amazonaws.com/twitter_production/profile_images/53781608/Photo_75_normal.jpg")
      expect(first.user.url).to eq("http://addictedtonew.com")
      expect(first.user.protected).to be_falsey
      expect(first.user.followers_count).to eq(486)
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

  it "parses xml with default namespace (amazon)" do
    file_contents = fixture_file("pita.xml")
    items = PITA::Items.parse(file_contents, single: true)

    aggregate_failures do
      expect(items.total_results).to eq(22)
      expect(items.total_pages).to eq(3)

      first = items.items[0]

      expect(first.asin).to eq("0321480791")
      expect(first.point).to eq("38.5351715088 -121.7948684692")
      expect(first.detail_page_url).to be_a(URI)
      expect(first.detail_page_url.to_s).to eq("http://www.amazon.com/gp/redirect.html%3FASIN=0321480791%26tag=ws%26lcode=xm2%26cID=2025%26ccmID=165953%26location=/o/ASIN/0321480791%253FSubscriptionId=dontbeaswoosh")
      expect(first.manufacturer).to eq("Addison-Wesley Professional")
      expect(first.product_group).to eq("<ProductGroup>Book</ProductGroup>")

      second = items.items[1]

      expect(second.asin).to eq("047022388X")
      expect(second.manufacturer).to eq("Wrox")
    end
  end

  it "parses xml that has attributes of elements" do
    items = CurrentWeather.parse(fixture_file("current_weather.xml"))
    first = items[0]

    aggregate_failures do
      expect(first.temperature).to eq(51)
      expect(first.feels_like).to eq(51)
      expect(first.current_condition).to eq("Sunny")
      expect(first.current_condition.icon).to eq("http://deskwx.weatherbug.com/images/Forecast/icons/cond007.gif")
    end
  end

  it "parses xml with attributes of elements that aren't :single => true" do
    feed = Atom::Feed.parse(fixture_file("atom.xml"))

    aggregate_failures do
      expect(feed.link.first.href).to eq("http://www.example.com")
      expect(feed.link.last.href).to eq("http://www.example.com/tv_shows.atom")
    end
  end

  it "parses xml with optional elements with embedded attributes" do
    expect do
      CurrentWeather.parse(fixture_file("current_weather_missing_elements.xml"))
    end.not_to raise_error
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

  it "parses xml that has elements with dashes" do
    commit = GitHub::Commit.parse(fixture_file("commit.xml"))

    aggregate_failures do
      expect(commit.message).to eq("move commands.rb and helpers.rb into commands/ dir")
      expect(commit.url).to eq("http://github.com/defunkt/github-gem/commit/c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b")
      expect(commit.id).to eq("c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b")
      expect(commit.committed_date).to eq(Date.parse("2008-03-02T16:45:41-08:00"))
      expect(commit.tree).to eq("28a1a1ca3e663d35ba8bf07d3f1781af71359b76")
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

  it "parses xml with multiple namespaces" do
    track = FedEx::TrackReply.parse(fixture_file("multiple_namespaces.xml"))

    aggregate_failures do
      expect(track.highest_severity).to eq("SUCCESS")
      expect(track.more_data).to be_falsey
      notification = track.notifications.first
      expect(notification.code).to eq(0)
      expect(notification.localized_message).to eq("Request was successfully processed.")
      expect(notification.message).to eq("Request was successfully processed.")
      expect(notification.severity).to eq("SUCCESS")
      expect(notification.source).to eq("trck")
      detail = track.trackdetails.first
      expect(detail.carrier_code).to eq("FDXG")
      expect(detail.est_delivery).to eq("2009-01-02T00:00:00")
      expect(detail.service_info).to eq("Ground-Package Returns Program-Domestic")
      expect(detail.status_code).to eq("OD")
      expect(detail.status_desc).to eq("On FedEx vehicle for delivery")
      expect(detail.tracking_number).to eq("9611018034267800045212")
      expect(detail.weight.units).to eq("LB")
      expect(detail.weight.value).to eq(2)
      events = detail.events
      expect(events.size).to eq(10)
      first_event = events[0]
      expect(first_event.eventdescription).to eq("On FedEx vehicle for delivery")
      expect(first_event.eventtype).to eq("OD")
      expect(first_event.timestamp).to eq("2009-01-02T06:00:00")
      expect(first_event.address.city).to eq("WICHITA")
      expect(first_event.address.countrycode).to eq("US")
      expect(first_event.address.residential).to be_falsey
      expect(first_event.address.state).to eq("KS")
      expect(first_event.address.zip).to eq("67226")
      last_event = events[-1]
      expect(last_event.eventdescription).to eq("In FedEx possession")
      expect(last_event.eventtype).to eq("IP")
      expect(last_event.timestamp).to eq("2008-12-27T09:40:00")
      expect(last_event.address.city).to eq("LONGWOOD")
      expect(last_event.address.countrycode).to eq("US")
      expect(last_event.address.residential).to be_falsey
      expect(last_event.address.state).to eq("FL")
      expect(last_event.address.zip).to eq("327506398")
      expect(track.tran_detail.cust_tran_id).to eq("20090102-111321")
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
    it "returns results with limited size: 6" do
      sizes = []
      Post.parse(fixture_file("posts.xml"), in_groups_of: 6) do |a|
        sizes << a.size
      end
      expect(sizes).to eq([6, 6, 6, 2])
    end

    it "returns results with limited size: 10" do
      sizes = []
      Post.parse(fixture_file("posts.xml"), in_groups_of: 10) do |a|
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
