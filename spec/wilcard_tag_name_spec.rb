require 'spec_helper'

describe "Wildcard Root Tag" do

  generic_class_xml = %{
    <root>
        <description>some description</description>
        <blarg name='blargname1' href='http://blarg.com'/>
        <blarg name='blargname2' href='http://blarg.com'/>
        <jello name='jelloname' href='http://jello.com'/>
        <subelement>
          <jello name='subjelloname' href='http://ohnojello.com' other='othertext'/>
        </subelement>
      </root>}

  module GenericBase
    class Base
      include Comparable
      include HappyMapper

      def initialize(params = {})
        @name = params[:name]
        @href = params[:href]
        @other = params[:other]
      end

      tag '*'
      attribute :name, String
      attribute :href, String
      attribute :other, String

      def <=>(compared)
        name <=> compared.name && href <=> compared.href && other <=> compared.other
      end
    end
    class Sub
      include HappyMapper
      tag 'subelement'
      has_one :jello, Base, :tag => 'jello'
    end
    class Root
      include HappyMapper
      tag 'root'
      element :description, String
      has_many :blargs, Base, :tag => 'blarg', :xpath => '.'
      has_many :jellos, Base, :tag => 'jello', :xpath => '.'
      has_many :subjellos, Base, :tag => 'jello', :xpath => 'subelement/.', :read_only => true
      has_one :sub_element, Sub
    end
  end

  describe "can have generic classes using tag '*'" do

    let(:subject) { GenericBase::Root.parse(generic_class_xml) }
    let(:xml) { Nokogiri::XML(subject.to_xml) }

    it 'should map different elements to same class' do
      expect(subject.blargs).not_to be_nil
      expect(subject.jellos).not_to be_nil
    end

    it 'should filter on xpath appropriately' do
      expect(subject.blargs.size).to eq(2)
      expect(subject.jellos.size).to eq(1)
      expect(subject.subjellos.size).to eq(1)
    end

    def base_with(name,href,other)
      GenericBase::Base.new(:name => name,:href => href,:other => other)
    end

    it 'should parse correct values onto generic class' do
      expect(subject.blargs[0]).to eq base_with('blargname1','http://blarg.com',nil)
      expect(subject.blargs[1]).to eq base_with('blargname2','http://blarg.com',nil)
      expect(subject.jellos[0]).to eq base_with('jelloname','http://jello.com',nil)
      expect(subject.subjellos[0]).to eq base_with('subjelloname','http://ohnojello.com','othertext')
    end

    def validate_xpath(xpath,name,href,other)
      expect(xml.xpath("#{xpath}/@name").text).to eq name
      expect(xml.xpath("#{xpath}/@href").text).to eq href
      expect(xml.xpath("#{xpath}/@other").text).to eq other
    end

    it 'should #to_xml using parent element tag name' do
      expect(xml.xpath('/root/description').text).to eq('some description')
      validate_xpath("/root/blarg[1]","blargname1","http://blarg.com","")
      validate_xpath("/root/blarg[2]","blargname2","http://blarg.com","")
      validate_xpath("/root/jello[1]","jelloname","http://jello.com","")
    end

    it "should properly respect child HappyMapper tags if tag isn't provided on the element defintion" do
      expect(xml.xpath('root/subelement').size).to eq(1)
    end
  end
end
