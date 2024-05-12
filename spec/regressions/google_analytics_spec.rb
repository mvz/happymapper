# frozen_string_literal: true

require "spec_helper"

RSpec.describe "parsing Google Analytics XML" do
  before do
    property_klass = Class.new do
      include HappyMapper

      tag "property"
      namespace "dxp"
      attribute :name, String
      attribute :value, String
    end
    stub_const "Property", property_klass

    goal_klass = Class.new do
      include HappyMapper

      # Google Analytics does a dirtry trick where a user with no goals
      # returns a profile without any goals data or the declared namespace
      # which means Nokogiri does not pick up the namespace automatically.
      # To fix this, we manually register the namespace to avoid bad XPath
      # expression. Dirty, but works.

      register_namespace "ga", "http://schemas.google.com/ga/2009"
      namespace "ga"

      tag "goal"
      attribute :active, HappyMapper::Boolean
      attribute :name, String
      attribute :number, Integer
      attribute :value, Float
    end
    stub_const "Goal", goal_klass

    profile_klass = Class.new do
      include HappyMapper

      tag "entry"
      element :title, String
      element :tableId, String, namespace: "dxp"

      has_many :properties, Property
      has_many :goals, Goal
    end
    stub_const "Profile", profile_klass

    entry_klass = Class.new do
      include HappyMapper

      tag "entry"
      element :id, String
      element :updated, DateTime
      element :title, String
      element :table_id, String, namespace: "dxp", tag: "tableId"
      has_many :properties, Property
    end
    stub_const "Entry", entry_klass

    feed_klass = Class.new do
      include HappyMapper

      tag "feed"
      element :id, String
      element :updated, DateTime
      element :title, String
      has_many :entries, Entry
    end
    stub_const "Feed", feed_klass
  end

  it "is able to parse google analytics api xml" do
    data = Feed.parse(fixture_file("analytics.xml"))

    aggregate_failures do
      expect(data.id).to eq("http://www.google.com/analytics/feeds/accounts/nunemaker@gmail.com")
      expect(data.entries.size).to eq(4)

      entry = data.entries[0]
      expect(entry.title).to eq("addictedtonew.com")
      expect(entry.properties.size).to eq(4)

      property = entry.properties[0]
      expect(property.name).to eq("ga:accountId")
      expect(property.value).to eq("85301")
    end
  end

  it "is able to parse google analytics profile xml with manually declared namespace" do
    data = Profile.parse(fixture_file("analytics_profile.xml"))

    aggregate_failures do
      expect(data.entries.size).to eq(6)
      entry = data.entries[0]
      expect(entry.title).to eq("www.homedepot.com")
      expect(entry.properties.size).to eq(6)
      expect(entry.goals.size).to eq(0)
    end
  end
end
