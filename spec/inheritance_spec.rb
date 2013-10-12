require 'spec_helper'

describe "Using inheritance to share elements and attributes" do

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

  describe "Overwrite" do
    let(:subject) do
      xml = '<overwrite love="love" naivety="trusting"><genetics>1001</genetics><immunities>Chicken Pox</immunities></overwrite>'
      Overwrite.parse(xml, single: true)
    end

    it 'overrides the parent elements and attributes' do
      expect(Overwrite.attributes.count).to be == Parent.attributes.count
      expect(Overwrite.elements.count).to be == Parent.elements.count
    end

    context "when parsing xml" do
      it 'parses the new overwritten attribut' do
        expect(subject.love).to be == "love"
      end

      it 'parses the new overwritten element' do
        expect(subject.genetics).to be == 1001
      end
    end

    context "when saving to xml" do
      subject do
        overwrite = Overwrite.new
        overwrite.genetics = 1
        overwrite.love = "love"
        Nokogiri::XML(overwrite.to_xml).root
      end

      it 'has only 1 genetics element' do
        expect(subject.xpath('//genetics').count).to be == 1
      end

      it 'has only 1 love attribute' do
        expect(subject.xpath('@love').text).to be == "love"
      end
    end
  end

  describe "Child", "a subclass of the Parent" do
    let(:subject) do
      xml = '<child love="99" naivety="trusting"><genetics>ABBA</genetics><immunities>Chicken Pox</immunities></child>'
      Child.parse(xml)
    end

    context "when parsing xml" do
      it 'should be possible to deserialize XML into a Child class instance' do
        expect(subject.love).to eq 99
        expect(subject.genetics.dna).to eq "ABBA"
        expect(subject.naivety).to eq "trusting"
        expect(subject.immunities).to have(1).item
      end
    end

    context "when saving to xml" do
      let(:subject) do
        child = Child.new
        child.love = 100
        child.naivety = 'Bright Eyed'
        child.immunities = [ "Small Pox", "Chicken Pox", "Mumps" ]
        genetics = Genetics.new
        genetics.dna = "GATTACA"
        child.genetics = genetics
        Nokogiri::XML(child.to_xml).root
      end

      it "saves both the Child and Parent attributes" do
        expect(subject.xpath("@naivety").text).to eq "Bright Eyed"
        expect(subject.xpath("@love").text).to eq "100"
      end

      it "saves both the Child and Parent elements" do
        expect(subject.xpath("genetics").text).to eq "GATTACA"
        expect(subject.xpath("immunities")).to have(3).items
      end
    end

  end
end
