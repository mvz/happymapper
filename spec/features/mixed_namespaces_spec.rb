# frozen_string_literal: true

require "spec_helper"

module MixedNamespaces
  class Address
    include HappyMapper

    namespace :prefix
    tag :address

    # Here each of the elements have their namespace set to nil to reset their
    # namespace so that it is not the same as the prefix namespace

    has_many :streets, String, tag: "street", namespace: nil

    has_one :house_number, String, tag: "housenumber", namespace: nil
    has_one :postcode, String, namespace: "different"
    has_one :city, String, namespace: nil
  end

  class RootCollision
    include HappyMapper

    register_namespace "xmlns", "http://www.unicornland.com/prefix"

    tag :address

    has_many :streets, String, tag: "street"
  end
end

RSpec.describe "A document with mixed namespaces" do
  #
  # Note that the parent element of the xml has the namespacing. The elements
  # contained within the xml do not share the parent element namespace so a
  # user of the library would likely need to clear the namespace on each of
  # these child elements.
  #
  let(:xml_document) do
    <<~XML
      <prefix:address location='home' xmlns:prefix="http://www.unicornland.com/prefix"
        xmlns:different="http://www.trollcountry.com/different">
        <street>Milchstrasse</street>
        <street>Another Street</street>
        <housenumber>23</housenumber>
        <different:postcode>26131</different:postcode>
        <city>Oldenburg</city>
      </prefix:address>
    XML
  end

  let(:address) do
    MixedNamespaces::Address.parse(xml_document, single: true)
  end

  it "has the correct streets" do
    expect(address.streets).to eq ["Milchstrasse", "Another Street"]
  end

  it "house number" do
    expect(address.house_number).to eq "23"
  end

  it "postcode" do
    expect(address.postcode).to eq "26131"
  end

  it "city" do
    expect(address.city).to eq "Oldenburg"
  end

  describe "and xmlns prefix collisions" do
    # Nokogiri calls out a potential problem with Nokogiri::Document.collect_namespaces
    # if the XML document has duplicate prefixes with different namespaces.
    # This document triggers the problem - the `xmlns` namespace will be overwritten
    # with the `http://override.com/breaks` value, so the root node won't be found.
    # The failure manifests as `nil` being returned from .parse.
    let(:collision_document) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <address location='home' xmlns="http://www.unicornland.com/prefix"
          xmlns:override="http://override.com/breaks">
          <street>Milchstrasse</street>
          <street>Another Street</street>
          <housenumber xmlns="http://override.com/breaks">23</housenumber>
          <housenumber xmlns="http://override.com/breaks">55</housenumber>
          <housenumber xmlns="http://override.com/breaks">88</housenumber>
          <different:postcode>26131</different:postcode>
          <different:city>Oldenburg</different:city>
          <housenumber xmlns="http://override.com/breaks">99</housenumber>
        </address>
      XML
    end

    let(:root_collision) do
      MixedNamespaces::RootCollision.parse(collision_document)
    end

    it "has the correct streets" do
      expect(root_collision.streets).to eq ["Milchstrasse", "Another Street"]
    end
  end
end
