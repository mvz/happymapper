require 'spec_helper'
require 'uri'

module Analytics
  class Property
    include HappyMapper

    tag 'property'
    namespace 'dxp'
    attribute :name, String
    attribute :value, String
  end

  class Goal
    include HappyMapper

    # Google Analytics does a dirtry trick where a user with no goals
    # returns a profile without any goals data or the declared namespace
    # which means Nokogiri does not pick up the namespace automatically.
    # To fix this, we manually register the namespace to avoid bad XPath
    # expression. Dirty, but works.

    register_namespace 'ga', 'http://schemas.google.com/ga/2009'
    namespace 'ga'

    tag 'goal'
    attribute :active, Boolean
    attribute :name, String
    attribute :number, Integer
    attribute :value, Float

    def clean_name
      name.gsub(/ga:/, '')
    end
  end

  class Profile
    include HappyMapper

    tag 'entry'
    element :title, String
    element :tableId, String, :namespace => 'dxp'

    has_many :properties, Property
    has_many :goals, Goal
  end


  class Entry
    include HappyMapper

    tag 'entry'
    element :id, String
    element :updated, DateTime
    element :title, String
    element :table_id, String, :namespace => 'dxp', :tag => 'tableId'
    has_many :properties, Property
  end

  class Feed
    include HappyMapper

    tag 'feed'
    element :id, String
    element :updated, DateTime
    element :title, String
    has_many :entries, Entry
  end
end

module Atom
  class Feed
    include HappyMapper
    tag 'feed'

    attribute :xmlns, String, :single => true
    element :id, String, :single => true
    element :title, String, :single => true
    element :updated, DateTime, :single => true
    element :link, String, :single => false, :attributes => {
        :rel => String,
        :type => String,
        :href => String
      }
    # has_many :entries, Entry # nothing interesting in the entries
  end
end

class Address
  include HappyMapper

  tag 'address'
  element :street, String
  element :postcode, String
  element :housenumber, String
  element :city, String
  element :country, String
end

class Feature
  include HappyMapper
  element :name, String, :xpath => './/text()'
end

class FeatureBullet
  include HappyMapper

  tag 'features_bullets'
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

module FamilySearch
  class AlternateIds
    include HappyMapper

    tag 'alternateIds'
    has_many :ids, String, :tag => 'id'
  end

  class Information
    include HappyMapper

    has_one :alternateIds, AlternateIds
  end

  class Person
    include HappyMapper

    attribute :version, String
    attribute :modified, Time
    attribute :id, String
    has_one :information, Information
  end

  class Persons
    include HappyMapper
    has_many :person, Person
  end

  class FamilyTree
    include HappyMapper

    tag 'familytree'
    attribute :version, String
    attribute :status_message, String, :tag => 'statusMessage'
    attribute :status_code, String, :tag => 'statusCode'
    has_one :persons, Persons
  end
end

module FedEx
  class Address
    include HappyMapper

    tag 'Address'
    namespace 'v2'
    element :city, String, :tag => 'City'
    element :state, String, :tag => 'StateOrProvinceCode'
    element :zip, String, :tag => 'PostalCode'
    element :countrycode, String, :tag => 'CountryCode'
    element :residential, Boolean, :tag => 'Residential'
  end

  class Event
    include HappyMapper

    tag 'Events'
    namespace 'v2'
    element :timestamp, String, :tag => 'Timestamp'
    element :eventtype, String, :tag => 'EventType'
    element :eventdescription, String, :tag => 'EventDescription'
    has_one :address, Address
  end

  class PackageWeight
    include HappyMapper

    tag 'PackageWeight'
    namespace 'v2'
    element :units, String, :tag => 'Units'
    element :value, Integer, :tag => 'Value'
  end

  class TrackDetails
    include HappyMapper

    tag 'TrackDetails'
    namespace 'v2'
    element   :tracking_number, String, :tag => 'TrackingNumber'
    element   :status_code, String, :tag => 'StatusCode'
    element   :status_desc, String, :tag => 'StatusDescription'
    element   :carrier_code, String, :tag => 'CarrierCode'
    element   :service_info, String, :tag => 'ServiceInfo'
    has_one   :weight, PackageWeight, :tag => 'PackageWeight'
    element   :est_delivery,  String, :tag => 'EstimatedDeliveryTimestamp'
    has_many  :events, Event
  end

  class Notification
    include HappyMapper

    tag 'Notifications'
    namespace 'v2'
    element :severity, String, :tag => 'Severity'
    element :source, String, :tag => 'Source'
    element :code, Integer, :tag => 'Code'
    element :message, String, :tag => 'Message'
    element :localized_message, String, :tag => 'LocalizedMessage'
  end

  class TransactionDetail
    include HappyMapper

    tag 'TransactionDetail'
    namespace 'v2'
    element :cust_tran_id, String, :tag => 'CustomerTransactionId'
  end

  class TrackReply
    include HappyMapper

    tag 'TrackReply'
    namespace 'v2'
    element   :highest_severity, String, :tag => 'HighestSeverity'
    element   :more_data, Boolean, :tag => 'MoreData'
    has_many  :notifications, Notification, :tag => 'Notifications'
    has_many  :trackdetails, TrackDetails, :tag => 'TrackDetails'
    has_one   :tran_detail, TransactionDetail, :tab => 'TransactionDetail'
  end
end

class Place
  include HappyMapper
  element :name, String
end

class Radar
  include HappyMapper
  has_many :places, Place, :tag => :place
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

  register_namespace 'fake', "faka:namespace"

  element :id, Integer
  element :text, String
  element :created_at, Time
  element :source, String
  element :truncated, Boolean
  element :in_reply_to_status_id, Integer
  element :in_reply_to_user_id, Integer
  element :favorited, Boolean
  element :non_existent, String, :tag => 'dummy', :namespace => 'fake'
  has_one :user, User
end

class CurrentWeather
  include HappyMapper

  tag 'ob'
  namespace 'aws'
  element :temperature, Integer, :tag => 'temp'
  element :feels_like, Integer, :tag => 'feels-like'
  element :current_condition, String, :tag => 'current-condition', :attributes => {:icon => String}
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

  tag 'address'
  element :street, String
  element :postcode, String
  element :housenumber, String
  element :city, String
  has_one :country, Country
  has_one :state, State
end

# for type coercion
class ProductGroup < String; end

module PITA
  class Item
    include HappyMapper

    tag 'Item' # if you put class in module you need tag
    element :asin, String, :tag => 'ASIN'
    element :detail_page_url, URI, :tag => 'DetailPageURL', :parser => :parse
    element :manufacturer, String, :tag => 'Manufacturer', :deep => true
    element :point, String, :tag => 'point', :namespace => 'georss'
    element :product_group, ProductGroup, :tag => 'ProductGroup', :deep => true, :parser => :new, :raw => true
  end

  class Items
    include HappyMapper

    tag 'Items' # if you put class in module you need tag
    element :total_results, Integer, :tag => 'TotalResults'
    element :total_pages, Integer, :tag => 'TotalPages'
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
    element :'committed-date', Date
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
    has_one :q1, QuarterTest::Quarter, :tag => 'q1'
    has_one :q2, QuarterTest::Quarter, :tag => 'q2'
    has_one :q3, QuarterTest::Quarter, :tag => 'q3'
    has_one :q4, QuarterTest::Quarter, :tag => 'q4'
  end
end

# To check for multiple primitives
class Artist
  include HappyMapper

  tag 'artist'
  element :images, String, :tag => "image", :single => false
  element :name, String
end

class Location
  include HappyMapper

  tag 'point'
  namespace "geo"
  element :latitude, String, :tag => "lat"
end

# Testing the XmlContent type
module Dictionary
  class Variant
    include HappyMapper
    tag 'var'
    has_xml_content

    def to_html
      xml_content.gsub('<tag>','<em>').gsub('</tag>','</em>')
    end
  end

  class Definition
    include HappyMapper

    tag 'def'
    element :text, XmlContent, :tag => 'dtext'
  end

  class Record
    include HappyMapper

    tag 'record'
    has_many :definitions, Definition
    has_many :variants, Variant, :tag => 'var'
  end
end

module AmbigousItems
  class Item
    include HappyMapper

    tag 'item'
    element :name, String
    element :item, String
  end
end

class PublishOptions
  include HappyMapper

  tag 'publishOptions'

  element :author, String, :tag => 'author'

  element :draft, Boolean, :tag => 'draft'
  element :scheduled_day, String, :tag => 'scheduledDay'
  element :scheduled_time, String, :tag => 'scheduledTime'
  element :published_day, String, :tag => 'publishDisplayDay'
  element :published_time, String, :tag => 'publishDisplayTime'
  element :created_day, String, :tag => 'publishDisplayDay'
  element :created_time, String, :tag => 'publishDisplayTime'

end

class Article
  include HappyMapper

  tag 'Article'
  namespace 'article'

  attr_writer :xml_value

  element :title, String
  element :text, String
  has_many :photos, 'Photo', :tag => 'Photo', :namespace => 'photo', :xpath => '/article:Article'
  has_many :galleries, 'Gallery', :tag => 'Gallery', :namespace => 'gallery'

  element :publish_options, PublishOptions, :tag => 'publishOptions', :namespace => 'article'

end

class PartiallyBadArticle
  include HappyMapper

  attr_writer :xml_value

  tag 'Article'
  namespace 'article'

  element :title, String
  element :text, String
  has_many :photos, 'Photo', :tag => 'Photo', :namespace => 'photo', :xpath => '/article:Article'
  has_many :videos, 'Video', :tag => 'Video', :namespace => 'video'

  element :publish_options, PublishOptions, :tag => 'publishOptions', :namespace => 'article'

end

class Photo
  include HappyMapper

  tag 'Photo'
  namespace 'photo'

  attr_writer :xml_value

  element :title, String
  element :publish_options, PublishOptions, :tag => 'publishOptions', :namespace => 'photo'

end

class Gallery
  include HappyMapper

  tag 'Gallery'
  namespace 'gallery'

  attr_writer :xml_value

  element :title, String

end

class Video
  include HappyMapper

  tag 'Video'
  namespace 'video'

  attr_writer :xml_value

  element :title, String
  element :publish_options, PublishOptions, :tag => 'publishOptions', :namespace => 'video'

end

class OptionalAttribute
  include HappyMapper
  tag 'address'

  attribute :street, String
end

class DefaultNamespaceCombi
  include HappyMapper


  register_namespace 'bk', "urn:loc.gov:books"
  register_namespace 'isbn', "urn:ISBN:0-395-36341-6"
  register_namespace 'p', "urn:loc.gov:people"
  namespace 'bk'

  tag 'book'

  element :title, String, :namespace => 'bk', :tag => "title"
  element :number, String, :namespace => 'isbn', :tag => "number"
  element :author, String, :namespace => 'p', :tag => "author"
end

describe HappyMapper do

  describe "being included into another class" do
    before do
      @klass = Class.new do
        include HappyMapper

        def self.to_s
          'Boo'
        end
      end
    end

    class Boo; include HappyMapper end

    it "should set attributes to an array" do
      @klass.attributes.should == []
    end

    it "should set @elements to a hash" do
      @klass.elements.should == []
    end

    it "should allow adding an attribute" do
      lambda {
        @klass.attribute :name, String
      }.should change(@klass, :attributes)
    end

    it "should allow adding an attribute containing a dash" do
      lambda {
        @klass.attribute :'bar-baz', String
      }.should change(@klass, :attributes)
    end

    it "should be able to get all attributes in array" do
      @klass.attribute :name, String
      @klass.attributes.size.should == 1
    end

    it "should allow adding an element" do
      lambda {
        @klass.element :name, String
      }.should change(@klass, :elements)
    end

    it "should allow adding an element containing a dash" do
      lambda {
        @klass.element :'bar-baz', String
      }.should change(@klass, :elements)

    end

    it "should be able to get all elements in array" do
      @klass.element(:name, String)
      @klass.elements.size.should == 1
    end

    it "should allow has one association" do
      @klass.has_one(:user, User)
      element = @klass.elements.first
      element.name.should == 'user'
      element.type.should == User
      element.options[:single].should == true
    end

    it "should allow has many association" do
      @klass.has_many(:users, User)
      element = @klass.elements.first
      element.name.should == 'users'
      element.type.should == User
      element.options[:single].should == false
    end

    it "should default tag name to lowercase class" do
      @klass.tag_name.should == 'boo'
    end

    it "should default tag name of class in modules to the last constant lowercase" do
      module Bar; class Baz; include HappyMapper; end; end
      Bar::Baz.tag_name.should == 'baz'
    end

    it "should allow setting tag name" do
      @klass.tag('FooBar')
      @klass.tag_name.should == 'FooBar'
    end

    it "should allow setting a namespace" do
      @klass.namespace(namespace = "boo")
      @klass.namespace.should == namespace
    end

    it "should provide #parse" do
      @klass.should respond_to(:parse)
    end
  end

  describe "#attributes" do
    it "should only return attributes for the current class" do
      Post.attributes.size.should == 7
      Status.attributes.size.should == 0
    end
  end

  describe "#elements" do
    it "should only return elements for the current class" do
      Post.elements.size.should == 0
      Status.elements.size.should == 10
    end
  end

  describe "#content" do
     it "should take String as default argument for type" do
       State.content :name
       address = Address.parse(fixture_file('address.xml'))
       address.state.name.should == "Lower Saxony"
       address.state.name.class == String
     end

     it "should work when specific type is provided" do
       Rate.content :value, Float
       Product.has_one :rate, Rate
       product = Product.parse(fixture_file('product_default_namespace.xml'), :single => true)
       product.rate.value.should == 120.25
       product.rate.class == Float
     end
  end

  it "should parse xml attributes into ruby objects" do
    posts = Post.parse(fixture_file('posts.xml'))
    posts.size.should == 20
    first = posts.first
    first.href.should == 'http://roxml.rubyforge.org/'
    first.hash.should == '19bba2ab667be03a19f67fb67dc56917'
    first.description.should == 'ROXML - Ruby Object to XML Mapping Library'
    first.tag.should == 'ruby xml gems mapping'
    first.time.should == Time.utc(2008, 8, 9, 5, 24, 20)
    first.others.should == 56
    first.extended.should == 'ROXML is a Ruby library designed to make it easier for Ruby developers to work with XML. Using simple annotations, it enables Ruby classes to be custom-mapped to XML. ROXML takes care of the marshalling and unmarshalling of mapped attributes so that developers can focus on building first-class Ruby classes.'
  end

  it "should parse xml elements to ruby objcts" do
    statuses = Status.parse(fixture_file('statuses.xml'))
    statuses.size.should == 20
    first = statuses.first
    first.id.should == 882281424
    first.created_at.should == Time.utc(2008, 8, 9, 5, 38, 12)
    first.source.should == 'web'
    first.truncated.should be_false
    first.in_reply_to_status_id.should == 1234
    first.in_reply_to_user_id.should == 12345
    first.favorited.should be_false
    first.user.id.should == 4243
    first.user.name.should == 'John Nunemaker'
    first.user.screen_name.should == 'jnunemaker'
    first.user.location.should == 'Mishawaka, IN, US'
    first.user.description.should == 'Loves his wife, ruby, notre dame football and iu basketball'
    first.user.profile_image_url.should == 'http://s3.amazonaws.com/twitter_production/profile_images/53781608/Photo_75_normal.jpg'
    first.user.url.should == 'http://addictedtonew.com'
    first.user.protected.should be_false
    first.user.followers_count.should == 486
  end

  it "should parse xml containing the desired element as root node" do
    address = Address.parse(fixture_file('address.xml'), :single => true)
    address.street.should == 'Milchstrasse'
    address.postcode.should == '26131'
    address.housenumber.should == '23'
    address.city.should == 'Oldenburg'
    address.country.class.should == Country
  end

  it "should parse text node correctly" do
    address = Address.parse(fixture_file('address.xml'), :single => true)
    address.country.name.should == 'Germany'
    address.country.code.should == 'de'
  end

  it "should treat Nokogiri::XML::Document as root" do
    doc = Nokogiri::XML(fixture_file('address.xml'))
    address = Address.parse(doc)
    address.class.should == Address
  end

  it "should parse xml with default namespace (amazon)" do
    file_contents = fixture_file('pita.xml')
    items = PITA::Items.parse(file_contents, :single => true)
    items.total_results.should == 22
    items.total_pages.should == 3
    first  = items.items[0]
    second = items.items[1]
    first.asin.should == '0321480791'
    first.point.should == '38.5351715088 -121.7948684692'
    first.detail_page_url.should be_a_kind_of(URI)
    first.detail_page_url.to_s.should == 'http://www.amazon.com/gp/redirect.html%3FASIN=0321480791%26tag=ws%26lcode=xm2%26cID=2025%26ccmID=165953%26location=/o/ASIN/0321480791%253FSubscriptionId=dontbeaswoosh'
    first.manufacturer.should == 'Addison-Wesley Professional'
    first.product_group.should == '<ProductGroup>Book</ProductGroup>'
    second.asin.should == '047022388X'
    second.manufacturer.should == 'Wrox'
  end

  it "should parse xml that has attributes of elements" do
    items = CurrentWeather.parse(fixture_file('current_weather.xml'))
    first = items[0]
    first.temperature.should == 51
    first.feels_like.should == 51
    first.current_condition.should == 'Sunny'
    first.current_condition.icon.should == 'http://deskwx.weatherbug.com/images/Forecast/icons/cond007.gif'
  end

  it "parses xml with attributes of elements that aren't :single => true" do
    feed = Atom::Feed.parse(fixture_file('atom.xml'))
    feed.link.first.href.should == 'http://www.example.com'
    feed.link.last.href.should == 'http://www.example.com/tv_shows.atom'
  end

  it "parses xml with optional elements with embedded attributes" do
    expect { CurrentWeather.parse(fixture_file('current_weather_missing_elements.xml')) }.to_not raise_error()
  end

  it "returns nil rather than empty array for absent values when :single => true" do
    address = Address.parse('<?xml version="1.0" encoding="UTF-8"?><foo/>', :single => true)
    address.should be_nil
  end

  it "should return same result for absent values when :single => true, regardless of :in_groups_of" do
    addr1 = Address.parse('<?xml version="1.0" encoding="UTF-8"?><foo/>', :single => true)
    addr2 = Address.parse('<?xml version="1.0" encoding="UTF-8"?><foo/>', :single => true, :in_groups_of => 10)
    addr1.should == addr2
  end

  it "should parse xml with nested elements" do
    radars = Radar.parse(fixture_file('radar.xml'))
    first = radars[0]
    first.places.size.should == 1
    first.places[0].name.should == 'Store'
    second = radars[1]
    second.places.size.should == 0
    third = radars[2]
    third.places.size.should == 2
    third.places[0].name.should == 'Work'
    third.places[1].name.should == 'Home'
  end

  it "should parse xml with element name different to class name" do
    game = QuarterTest::Game.parse(fixture_file('quarters.xml'))
    game.q1.start.should == '4:40:15 PM'
    game.q2.start.should == '5:18:53 PM'
  end

  it "should parse xml that has elements with dashes" do
    commit = GitHub::Commit.parse(fixture_file('commit.xml'))
    commit.message.should == "move commands.rb and helpers.rb into commands/ dir"
    commit.url.should == "http://github.com/defunkt/github-gem/commit/c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b"
    commit.id.should == "c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b"
    commit.committed_date.should == Date.parse("2008-03-02T16:45:41-08:00")
    commit.tree.should == "28a1a1ca3e663d35ba8bf07d3f1781af71359b76"
  end

  it "should parse xml with no namespace" do
    product = Product.parse(fixture_file('product_no_namespace.xml'), :single => true)
    product.title.should == "A Title"
    product.feature_bullets.bug.should == 'This is a bug'
    product.feature_bullets.features.size.should == 2
    product.feature_bullets.features[0].name.should == 'This is feature text 1'
    product.feature_bullets.features[1].name.should == 'This is feature text 2'
  end

  it "should parse xml with default namespace" do
    product = Product.parse(fixture_file('product_default_namespace.xml'), :single => true)
    product.title.should == "A Title"
    product.feature_bullets.bug.should == 'This is a bug'
    product.feature_bullets.features.size.should == 2
    product.feature_bullets.features[0].name.should == 'This is feature text 1'
    product.feature_bullets.features[1].name.should == 'This is feature text 2'
  end

  it "should parse xml with single namespace" do
    product = Product.parse(fixture_file('product_single_namespace.xml'), :single => true)
    product.title.should == "A Title"
    product.feature_bullets.bug.should == 'This is a bug'
    product.feature_bullets.features.size.should == 2
    product.feature_bullets.features[0].name.should == 'This is feature text 1'
    product.feature_bullets.features[1].name.should == 'This is feature text 2'
  end

  it "should parse xml with multiple namespaces" do
    track = FedEx::TrackReply.parse(fixture_file('multiple_namespaces.xml'))
    track.highest_severity.should == 'SUCCESS'
    track.more_data.should be_false
    notification = track.notifications.first
    notification.code.should == 0
    notification.localized_message.should == 'Request was successfully processed.'
    notification.message.should == 'Request was successfully processed.'
    notification.severity.should == 'SUCCESS'
    notification.source.should == 'trck'
    detail = track.trackdetails.first
    detail.carrier_code.should == 'FDXG'
    detail.est_delivery.should == '2009-01-02T00:00:00'
    detail.service_info.should == 'Ground-Package Returns Program-Domestic'
    detail.status_code.should == 'OD'
    detail.status_desc.should == 'On FedEx vehicle for delivery'
    detail.tracking_number.should == '9611018034267800045212'
    detail.weight.units.should == 'LB'
    detail.weight.value.should == 2
    events = detail.events
    events.size.should == 10
    first_event = events[0]
    first_event.eventdescription.should == 'On FedEx vehicle for delivery'
    first_event.eventtype.should == 'OD'
    first_event.timestamp.should == '2009-01-02T06:00:00'
    first_event.address.city.should == 'WICHITA'
    first_event.address.countrycode.should == 'US'
    first_event.address.residential.should be_false
    first_event.address.state.should == 'KS'
    first_event.address.zip.should == '67226'
    last_event = events[-1]
    last_event.eventdescription.should == 'In FedEx possession'
    last_event.eventtype.should == 'IP'
    last_event.timestamp.should == '2008-12-27T09:40:00'
    last_event.address.city.should == 'LONGWOOD'
    last_event.address.countrycode.should == 'US'
    last_event.address.residential.should be_false
    last_event.address.state.should == 'FL'
    last_event.address.zip.should == '327506398'
    track.tran_detail.cust_tran_id.should == '20090102-111321'
  end

  it "should be able to parse google analytics api xml" do
    data = Analytics::Feed.parse(fixture_file('analytics.xml'))
    data.id.should == 'http://www.google.com/analytics/feeds/accounts/nunemaker@gmail.com'
    data.entries.size.should == 4

    entry = data.entries[0]
    entry.title.should == 'addictedtonew.com'
    entry.properties.size.should == 4

    property = entry.properties[0]
    property.name.should == 'ga:accountId'
    property.value.should == '85301'
  end

  it "should be able to parse google analytics profile xml with manually declared namespace" do
    data = Analytics::Profile.parse(fixture_file('analytics_profile.xml'))
    data.entries.size.should == 6

    entry = data.entries[0]
    entry.title.should == 'www.homedepot.com'
    entry.properties.size.should == 6
    entry.goals.size.should == 0
  end

  it "should allow instantiating with a string" do
    module StringFoo
      class Bar
        include HappyMapper
        has_many :things, 'StringFoo::Thing'
      end

      class Thing
        include HappyMapper
      end
    end
  end

  it "should parse family search xml" do
    tree = FamilySearch::FamilyTree.parse(fixture_file('family_tree.xml'))
    tree.version.should == '1.0.20071213.942'
    tree.status_message.should == 'OK'
    tree.status_code.should == '200'
    tree.persons.person.size.should == 1
    tree.persons.person.first.version.should == '1199378491000'
    tree.persons.person.first.modified.should == Time.utc(2008, 1, 3, 16, 41, 31) # 2008-01-03T09:41:31-07:00
    tree.persons.person.first.id.should == 'KWQS-BBQ'
    tree.persons.person.first.information.alternateIds.ids.should_not be_kind_of(String)
    tree.persons.person.first.information.alternateIds.ids.size.should == 8
  end

  it "should parse multiple images" do
    artist = Artist.parse(fixture_file('multiple_primitives.xml'))
    artist.name.should == "value"
    artist.images.size.should == 2
  end

  it "should parse lastfm namespaces" do
    l = Location.parse(fixture_file('lastfm.xml'))
    l.first.latitude.should == "51.53469"
  end

  describe "Parse optional attributes" do

    it "should parse an empty String as empty" do
      a = OptionalAttribute.parse(fixture_file('optional_attributes.xml'))
      a[0].street.should == ""
    end

    it "should parse a String with value" do
      a = OptionalAttribute.parse(fixture_file('optional_attributes.xml'))
      a[1].street.should == "Milchstrasse"
    end

    it "should parse a String with value" do
      a = OptionalAttribute.parse(fixture_file('optional_attributes.xml'))
      a[2].street.should be_nil
    end

  end

  describe "Default namespace combi" do
    before(:each) do
      file_contents = fixture_file('default_namespace_combi.xml')
      @book = DefaultNamespaceCombi.parse(file_contents, :single => true)
    end

    it "should parse author" do
      @book.author.should == "Frank Gilbreth"
    end

    it "should parse title" do
      @book.title.should == "Cheaper by the Dozen"
    end

    it "should parse number" do
      @book.number.should == "1568491379"
    end

  end

  describe 'Xml Content' do
    before(:each) do
      file_contents = fixture_file('dictionary.xml')
      @records = Dictionary::Record.parse(file_contents)
    end

    it "should parse XmlContent" do
      @records.first.definitions.first.text.should ==
        'a large common parrot, <bn>Cacatua galerita</bn>, predominantly white, with yellow on the undersides of wings and tail and a forward curving yellow crest, found in Australia, New Guinea and nearby islands.'
    end

    it "should save object's xml content" do
      @records.first.variants.first.xml_content.should ==
        'white <tag>cockatoo</tag>'
      @records.first.variants.last.to_html.should ==
        '<em>white</em> cockatoo'
    end
  end

  it "should parse ambigous items" do
    items = AmbigousItems::Item.parse(fixture_file('ambigous_items.xml'), :xpath => '/ambigous/my-items')
    items.map(&:name).should == %w(first second third).map{|s| "My #{s} item" }
  end


  context Article do
    it "should parse the publish options for Article and Photo" do
      @article.title.should_not be_nil
      @article.text.should_not be_nil
      @article.photos.should_not be_nil
      @article.photos.first.title.should_not be_nil
    end

    it "should parse the publish options for Article" do
      @article.publish_options.should_not be_nil
    end

    it "should parse the publish options for Photo" do
      @article.photos.first.publish_options.should_not be_nil
    end

    it "should only find only items at the parent level" do
      @article.photos.length.should == 1
    end

    before(:all) do
      @article = Article.parse(fixture_file('subclass_namespace.xml'))
    end

  end

  context "Namespace is missing because an optional element that uses it is not present" do
     it "should parse successfully" do
       @article = PartiallyBadArticle.parse(fixture_file('subclass_namespace.xml'))
       @article.should_not be_nil
       @article.title.should_not be_nil
       @article.text.should_not be_nil
       @article.photos.should_not be_nil
       @article.photos.first.title.should_not be_nil
     end
   end


   describe "with limit option" do
     it "should return results with limited size: 6" do
       sizes = []
       posts = Post.parse(fixture_file('posts.xml'), :in_groups_of => 6) do |a|
         sizes << a.size
       end
       sizes.should == [6, 6, 6, 2]
     end

     it "should return results with limited size: 10" do
       sizes = []
       posts = Post.parse(fixture_file('posts.xml'), :in_groups_of => 10) do |a|
         sizes << a.size
       end
       sizes.should == [10, 10]
     end
   end

  context "when letting user set Nokogiri::XML::ParseOptions" do
    let(:default) {
      Class.new do
        include HappyMapper
        element :item, String
      end
    }
    let(:custom) {
      Class.new do
        include HappyMapper
        element :item, String
        with_nokogiri_config do |config|
          config.default_xml
        end
      end
    }

    it 'initializes @nokogiri_config_callback to nil' do
      default.nokogiri_config_callback.should be_nil
    end

    it 'defaults to Nokogiri::XML::ParseOptions::STRICT' do
     expect { default.parse(fixture_file('set_config_options.xml')) }.to raise_error(Nokogiri::XML::SyntaxError)
    end

    it 'accepts .on_config callback' do
      custom.nokogiri_config_callback.should_not be_nil
    end

    it 'parses according to @nokogiri_config_callback' do
      expect { custom.parse(fixture_file('set_config_options.xml')) }.to_not raise_error
    end

    it 'can clear @nokogiri_config_callback' do
      custom.with_nokogiri_config {}
      expect { custom.parse(fixture_file('set_config_options.xml')) }.to raise_error(Nokogiri::XML::SyntaxError)
    end
  end

end
