# frozen_string_literal: true

require "spec_helper"

module GenericBase
  class Wild
    include Comparable
    include HappyMapper

    def initialize(params = {})
      @name = params[:name]
      @href = params[:href]
      @other = params[:other]
    end

    tag "*"
    attribute :name, String
    attribute :href, String
    attribute :other, String

    def <=>(other)
      result = name <=> other.name
      return result unless result == 0

      result = href <=> other.href
      return result unless result == 0

      self.other <=> other.other
    end
  end

  class SubList
    include HappyMapper

    tag "sublist"

    has_many :jellos, Wild, tag: "jello"
    has_many :puddings, Wild, tag: "pudding"
  end

  class Fixed
    include HappyMapper

    tag "fixed_element"

    attribute :name, String
  end

  class Auto
    include HappyMapper

    attribute :name, String
  end

  class Root
    include HappyMapper

    tag "root"
    element :description, String
    has_many :blargs, Wild, tag: "blarg", xpath: "."
    has_many :jellos, Wild, tag: "jello", xpath: "."

    has_one :sublist, SubList

    has_many :subjellos, Wild, xpath: "sublist/.", tag: "jello", read_only: true
    has_many :subwilds, Wild, xpath: "sublist/.", read_only: true

    has_one :renamed_fixed, Fixed, tag: "myfixed"
    has_one :fixed_element, Fixed
    has_one :auto, Auto
  end
end

RSpec.describe "classes with a wildcard tag" do
  let(:root) { GenericBase::Root.parse(generic_class_xml) }
  let(:generic_class_xml) do
    <<~XML
      <root>
        <description>some description</description>
        <blarg name='blargname1' href='http://blarg.com'/>
        <blarg name='blargname2' href='http://blarg.com'/>
        <jello name='jelloname' href='http://jello.com'/>
        <sublist>
          <jello name='subjelloname' href='http://ohnojello.com' other='othertext'/>
          <pudding name='puddingname' href='http://pudding.com'/>
        </sublist>
        <myfixed name='renamedfixed'/>
        <fixed_element name='foobar'/>
        <auto name='i am auto'/>
      </root>
    XML
  end

  describe ".parse" do
    it "maps different elements to same class" do
      aggregate_failures do
        expect(root.blargs).to contain_exactly(GenericBase::Wild, GenericBase::Wild)
        expect(root.jellos).to contain_exactly(GenericBase::Wild)
      end
    end

    it "filters on xpath appropriately" do
      aggregate_failures do
        expect(root.jellos.size).to eq 1
        expect(root.subjellos.size).to eq 1
      end
    end

    def base_with(name, href, other)
      GenericBase::Wild.new(name: name, href: href, other: other)
    end

    it "parses correct values onto generic class" do
      aggregate_failures do
        expect(root.blargs[0]).to eq base_with("blargname1", "http://blarg.com", nil)
        expect(root.blargs[1]).to eq base_with("blargname2", "http://blarg.com", nil)
        expect(root.jellos[0]).to eq base_with("jelloname", "http://jello.com", nil)
        expect(root.subjellos[0])
          .to eq base_with("subjelloname", "http://ohnojello.com", "othertext")
      end
    end

    it "maps all elements matching xpath if tag is not specified" do
      aggregate_failures do
        expect(root.subwilds.size).to eq 2
      end
    end
  end

  describe "#to_xml" do
    let(:xml) { Nokogiri::XML(root.to_xml) }

    def validate_xpath(xpath, name, href, other)
      expect(xml.xpath("#{xpath}/@name").text).to eq name
      expect(xml.xpath("#{xpath}/@href").text).to eq href
      expect(xml.xpath("#{xpath}/@other").text).to eq other
    end

    it "uses the tag name specified by the parent element for wildcard elements" do
      aggregate_failures do
        expect(xml.xpath("/root/description").text).to eq("some description")
        validate_xpath("/root/blarg[1]", "blargname1", "http://blarg.com", "")
        validate_xpath("/root/blarg[2]", "blargname2", "http://blarg.com", "")
        validate_xpath("/root/jello[1]", "jelloname", "http://jello.com", "")
        validate_xpath("/root/sublist/jello[1]", "subjelloname", "http://ohnojello.com",
                       "othertext")
        validate_xpath("/root/sublist/pudding[1]", "puddingname", "http://pudding.com", "")
      end
    end

    it "uses the tag name specified by the parent element for fixed elements" do
      expect(xml.xpath("/root/myfixed").size).to eq 1
    end

    it "uses the element's specified tag name if the tag is not specified by the parent" do
      expect(xml.xpath("root/fixed_element").size).to eq(1)
    end

    it "uses the element's auto-generated tag name if the tag is not specified elsewhere" do
      expect(xml.xpath("root/auto").size).to eq(1)
    end
  end
end
