# frozen_string_literal: true

RSpec.describe "parsing lastfm xml" do
  before do
    klass = Class.new do
      include HappyMapper

      tag "point"
      namespace "geo"
      element :latitude, String, tag: "lat"
    end
    stub_const "Location", klass
  end

  it "maps namespaces correctly" do
    l = Location.parse(fixture_file("lastfm.xml"))
    expect(l.first.latitude).to eq("51.53469")
  end
end
