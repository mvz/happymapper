require "spec_helper"

module Sheep
  class Item
    include HappyMapper
  end

  class Navigator
    include HappyMapper
    tag 'navigator'

    # This is purposefully set to have the name 'items' with the tag 'item'.
    # The idea is that it should not find the empty items contained within the
    # xml and return an empty array. This exercises the order of how nodes
    # are searched for within an XML document.
    has_many :items, Item, :tag => 'item'

    has_many :items_with_a_different_name, Item, :tag => 'item'

  end
end

describe "emptyness" do
  let(:xml) do
    <<-EOF
    <navigator>
      <items/>
    </navigator>
    EOF
  end

  let(:navigator) do
    Sheep::Navigator.parse(xml)
  end

  it "returns an empty array" do
    navigator.items_with_a_different_name.should be_empty
  end

  it "returns an empty array" do
    navigator.items.should be_empty
  end
end
