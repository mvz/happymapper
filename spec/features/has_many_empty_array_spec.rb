# frozen_string_literal: true

require "spec_helper"

module Sheep
  class Item
    include HappyMapper
  end

  class Navigator
    include HappyMapper
    tag "navigator"

    # This is purposefully set to have the name 'items' with the tag 'item'.
    # The idea is that it should not find the empty items contained within the
    # xml and return an empty array. This exercises the order of how nodes
    # are searched for within an XML document.
    has_many :items, Item, tag: "item"

    has_many :items_with_a_different_name, Item, tag: "item"
  end
end

RSpec.describe "empty arrays of items based on tags" do
  let(:xml) do
    <<-XML
    <navigator>
      <items/>
    </navigator>
    XML
  end

  let(:navigator) do
    Sheep::Navigator.parse(xml)
  end

  it "returns an empty array" do
    expect(navigator.items_with_a_different_name).to be_empty
  end

  it "looks for items based on the element tag, not the element name" do
    expect(navigator.items).to be_empty
  end
end
