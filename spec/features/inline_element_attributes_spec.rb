# frozen_string_literal: true

require "spec_helper"

RSpec.describe "specifying element attributes inline" do
  let(:currentweather_klass) do
    Class.new do
      include HappyMapper

      tag "ob"
      namespace "aws"
      element :temperature, Integer, tag: "temp"
      element :feels_like, Integer, tag: "feels-like"
      element :current_condition, String, tag: "current-condition",
                                          attributes: { icon: String }
    end
  end

  let(:atomfeed_klass) do
    Class.new do
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
    end
  end

  it "adds the values of the attributes to the element" do
    items = currentweather_klass.parse(fixture_file("current_weather.xml"))
    first = items[0]

    aggregate_failures do
      expect(first.temperature).to eq(51)
      expect(first.feels_like).to eq(51)
      expect(first.current_condition).to eq("Sunny")
      expect(first.current_condition.icon).to eq("http://deskwx.weatherbug.com/images/Forecast/icons/cond007.gif")
    end
  end

  it "parses xml when the element with embedded attributes is not present in the xml" do
    expect do
      currentweather_klass.parse(fixture_file("current_weather_missing_elements.xml"))
    end.not_to raise_error
  end

  it "parses xml with attributes of elements that aren't :single => true" do
    feed = atomfeed_klass.parse(fixture_file("atom.xml"))

    aggregate_failures do
      expect(feed.link.first.href).to eq("http://www.example.com")
      expect(feed.link.last.href).to eq("http://www.example.com/tv_shows.atom")
    end
  end
end
