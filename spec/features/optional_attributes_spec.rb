# frozen_string_literal: true

RSpec.describe "Parsing optional attributes" do
  before do
    klass = Class.new do
      include HappyMapper

      tag "address"

      attribute :street, String
    end
    stub_const "OptionalAttribute", klass
  end

  let(:parsed_result) { OptionalAttribute.parse(fixture_file("optional_attributes.xml")) }

  it "parses an empty String as empty" do
    expect(parsed_result[0].street).to eq("")
  end

  it "parses a String with value" do
    expect(parsed_result[1].street).to eq("Milchstrasse")
  end

  it "parses an element with no value for the attribute" do
    expect(parsed_result[2].street).to be_nil
  end
end
