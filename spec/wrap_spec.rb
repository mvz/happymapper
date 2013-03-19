require 'spec_helper'

describe "wrap which allows you to specify a wrapper element" do

  module Wrap
    class SubClass
      include HappyMapper
      tag 'subclass'
      attribute :myattr, String
      has_many :items, String, :tag => 'item'
    end
    class Root
      include HappyMapper
      tag 'root'
      attribute :attr1, String
      element :name, String
      wrap 'mywraptag' do
        element :description, String
        has_one :subclass, SubClass
      end
      element :number, Integer
    end
  end

  describe ".parse" do
    context "when given valid XML" do
      let(:subject) { Wrap::Root.parse fixture_file('wrapper.xml') }

      it 'sets the values correctly' do
        expect(subject.attr1).to eq 'somevalue'
        expect(subject.name).to eq 'myname'
        expect(subject.description).to eq 'some description'
        expect(subject.subclass.myattr).to eq 'attrvalue'
        expect(subject.subclass.items).to have(2).items
        expect(subject.subclass.items[0]).to eq 'item1'
        expect(subject.subclass.items[1]).to eq 'item2'
        expect(subject.number).to eq 12345
      end
    end

    context "when initialized without XML" do
      let(:subject) { Wrap::Root.new }

      it "anonymous classes are created so nil class values does not occur" do
        expect { subject.description = 'anything' }.to_not raise_error
      end
    end
  end

  describe ".to_xml" do
    let(:subject) do
      root = Wrap::Root.new
      root.attr1 = 'somevalue'
      root.name = 'myname'
      root.description = 'some description'
      root.number = 12345

      subclass = Wrap::SubClass.new
      subclass.myattr = 'attrvalue'
      subclass.items = []
      subclass.items << 'item1'
      subclass.items << 'item2'

      root.subclass = subclass

      root
    end

    it "generates the correct xml" do
      xml = Nokogiri::XML(subject.to_xml)
      expect(xml.xpath('/root/@attr1').text).to eq 'somevalue'
      expect(xml.xpath('/root/name').text).to eq 'myname'
      expect(xml.xpath('/root/mywraptag/description').text).to eq 'some description'
      expect(xml.xpath('/root/mywraptag/subclass/@myattr').text).to eq 'attrvalue'
      expect(xml.xpath('/root/mywraptag/subclass/item')).to have(2).items
      expect(xml.xpath('/root/mywraptag/subclass/item[1]').text).to eq 'item1'
      expect(xml.xpath('/root/mywraptag/subclass/item[2]').text).to eq 'item2'
      expect(xml.xpath('/root/number').text).to eq '12345'
    end

  end
end