# frozen_string_literal: true

require "spec_helper"

module Inheritance
  class Genetics
    include HappyMapper

    content :dna, String
  end

  class Parent
    include HappyMapper

    attribute :love, Integer
    element :genetics, Genetics
  end

  class Child < Parent
    include HappyMapper

    attribute :naivety, String
    has_many :immunities, String
  end

  class Overwrite < Parent
    include HappyMapper

    attribute :love, String
    element :genetics, Integer
  end
end

RSpec.describe "Using inheritance to share elements and attributes" do
  describe "Overwrite" do
    let(:overwrite) do
      xml =
        '<overwrite love="love" naivety="trusting">' \
        "<genetics>1001</genetics><immunities>Chicken Pox</immunities>" \
        "</overwrite>"
      Inheritance::Overwrite.parse(xml, single: true)
    end

    it "overrides the parent elements and attributes" do
      aggregate_failures do
        expect(Inheritance::Overwrite.attributes.count)
          .to eq Inheritance::Parent.attributes.count
        expect(Inheritance::Overwrite.elements.count)
          .to eq Inheritance::Parent.elements.count
      end
    end

    context "when parsing xml" do
      it "parses the new overwritten attribut" do
        expect(overwrite.love).to eq "love"
      end

      it "parses the new overwritten element" do
        expect(overwrite.genetics).to eq 1001
      end
    end

    context "when saving to xml" do
      let(:xml) do
        overwrite = Inheritance::Overwrite.new
        overwrite.genetics = 1
        overwrite.love = "love"
        Nokogiri::XML(overwrite.to_xml).root
      end

      it "has only 1 genetics element" do
        expect(xml.xpath("//genetics").count).to eq 1
      end

      it "has only 1 love attribute" do
        expect(xml.xpath("@love").text).to eq "love"
      end
    end
  end

  describe "Child", "a subclass of the Parent" do
    let(:child) do
      xml =
        '<child love="99" naivety="trusting">' \
        "<genetics>ABBA</genetics><immunities>Chicken Pox</immunities>" \
        "</child>"
      Inheritance::Child.parse(xml)
    end

    context "when parsing xml" do
      it "is possible to deserialize XML into a Child class instance" do
        aggregate_failures do
          expect(child.love).to eq 99
          expect(child.genetics.dna).to eq "ABBA"
          expect(child.naivety).to eq "trusting"
          expect(child.immunities.size).to eq(1)
        end
      end
    end

    context "when saving to xml" do
      let(:xml) do
        child = Inheritance::Child.new
        child.love = 100
        child.naivety = "Bright Eyed"
        child.immunities = ["Small Pox", "Chicken Pox", "Mumps"]
        genetics = Inheritance::Genetics.new
        genetics.dna = "GATTACA"
        child.genetics = genetics
        Nokogiri::XML(child.to_xml).root
      end

      it "saves both the Child and Parent attributes" do
        aggregate_failures do
          expect(xml.xpath("@naivety").text).to eq "Bright Eyed"
          expect(xml.xpath("@love").text).to eq "100"
        end
      end

      it "saves both the Child and Parent elements" do
        aggregate_failures do
          expect(xml.xpath("genetics").text).to eq "GATTACA"
          expect(xml.xpath("immunities").size).to eq(3)
        end
      end
    end
  end
end
