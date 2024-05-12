# frozen_string_literal: true

require "spec_helper"
require "uri"

RSpec.describe "parsing an amazon search result" do
  before do
    # for type coercion
    productgroup_klass = Class.new(String)
    stub_const "ProductGroup", productgroup_klass

    item_klass = Class.new do
      include HappyMapper

      tag "Item"
      element :asin, String, tag: "ASIN"
      element :detail_page_url, URI, tag: "DetailPageURL", parser: :parse
      element :manufacturer, String, tag: "Manufacturer", deep: true
      element :point, String, tag: "point", namespace: "georss"
      element :product_group, ProductGroup, tag: "ProductGroup", deep: true,
                                            parser: :new, raw: true
    end
    stub_const "Item", item_klass

    items_klass = Class.new do
      include HappyMapper

      tag "Items"
      element :total_results, Integer, tag: "TotalResults"
      element :total_pages, Integer, tag: "TotalPages"
      has_many :items, Item
    end
    stub_const "Items", items_klass
  end

  it "parses xml with default and other namespace and various custom parsing" do
    file_contents = fixture_file("pita.xml")
    items = Items.parse(file_contents, single: true)

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
end
