# frozen_string_literal: true

require "spec_helper"

module Wrap
  class SubClass
    include HappyMapper

    tag "subclass"
    attribute :myattr, String
    has_many :items, String, tag: "item"
  end

  class Root
    include HappyMapper

    tag "root"
    attribute :attr1, String
    element :name, String
    wrap "mywraptag" do
      element :description, String
      has_one :subclass, SubClass
    end
    element :number, Integer
  end

  class Root2
    include HappyMapper

    tag "root"

    wrap "tag_wrapper", tag: "mywraptag" do
      element :description, String
    end
  end
end

RSpec.describe "wrap which allows you to specify a wrapper element" do
  describe ".parse" do
    context "when given valid XML" do
      let(:root) { Wrap::Root.parse fixture_file("wrapper.xml") }

      it "sets the values correctly" do
        aggregate_failures do
          expect(root.attr1).to eq "somevalue"
          expect(root.name).to eq "myname"
          expect(root.description).to eq "some description"
          expect(root.subclass.myattr).to eq "attrvalue"
          expect(root.subclass.items.size).to eq(2)
          expect(root.subclass.items[0]).to eq "item1"
          expect(root.subclass.items[1]).to eq "item2"
          expect(root.number).to eq 12_345
        end
      end
    end

    context "with alternate wrapper name" do
      let(:root) { Wrap::Root2.parse fixture_file("wrapper.xml") }

      it "sets the values correctly" do
        expect(root.description).to eq "some description"
      end
    end

    context "when initialized without XML" do
      let(:root) { Wrap::Root.new }

      it "creates anonymous classes so nil class values do not occur" do
        expect { root.description = "anything" }.not_to raise_error
      end
    end
  end

  describe ".to_xml" do
    let(:root) do
      root = Wrap::Root.new
      root.attr1 = "somevalue"
      root.name = "myname"
      root.description = "some description"
      root.number = 12_345

      subclass = Wrap::SubClass.new
      subclass.myattr = "attrvalue"
      subclass.items = []
      subclass.items << "item1"
      subclass.items << "item2"

      root.subclass = subclass

      root
    end

    it "generates the correct xml" do
      xml = Nokogiri::XML(root.to_xml)

      aggregate_failures do
        expect(xml.xpath("/root/@attr1").text).to eq "somevalue"
        expect(xml.xpath("/root/name").text).to eq "myname"
        expect(xml.xpath("/root/mywraptag/description").text).to eq "some description"
        expect(xml.xpath("/root/mywraptag/subclass/@myattr").text).to eq "attrvalue"
        expect(xml.xpath("/root/mywraptag/subclass/item").size).to eq(2)
        expect(xml.xpath("/root/mywraptag/subclass/item[1]").text).to eq "item1"
        expect(xml.xpath("/root/mywraptag/subclass/item[2]").text).to eq "item2"
        expect(xml.xpath("/root/number").text).to eq "12345"
      end
    end
  end
end
