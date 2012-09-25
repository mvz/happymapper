require File.dirname(__FILE__) + '/spec_helper.rb'       

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

describe HappyMapper do
  describe "can parse and #to_xml taking into account a holder tag that won't be defined as a HappyMapper class" do
    
    it 'should parse xml' do
      root = Wrap::Root.parse(fixture_file('wrapper.xml'))        
      root.attr1.should == 'somevalue'
      root.name.should == 'myname'
      root.description.should == 'some description'
      root.subclass.myattr.should == 'attrvalue'
      root.subclass.items.should have(2).items
      root.subclass.items[0].should == 'item1'
      root.subclass.items[1].should == 'item2'
      root.number.should == 12345      
    end
    
    it "should initialize anonymous classes so nil class values don't occur" do
      root = Wrap::Root.new
      lambda { root.description = 'anything' }.should_not raise_error
    end
    
    it 'should #to_xml with wrapped tag' do
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
                
      xml = Nokogiri::XML(root.to_xml)
      xml.xpath('/root/@attr1').text.should == 'somevalue'
      xml.xpath('/root/name').text.should == 'myname'
      xml.xpath('/root/mywraptag/description').text.should == 'some description'
      xml.xpath('/root/mywraptag/subclass/@myattr').text.should == 'attrvalue'
      xml.xpath('/root/mywraptag/subclass/item').should have(2).items
      xml.xpath('/root/mywraptag/subclass/item[1]').text.should == 'item1'
      xml.xpath('/root/mywraptag/subclass/item[2]').text.should == 'item2'
      xml.xpath('/root/number').text.should == '12345'
    end    
  end
end