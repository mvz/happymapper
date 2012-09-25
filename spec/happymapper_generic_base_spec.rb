require File.dirname(__FILE__) + '/spec_helper.rb'
           

generic_class_xml = %{
  <root>
    <description>some description</description>
    <blarg name='blargname1' href='http://blarg.com'/>
    <blarg name='blargname2' href='http://blarg.com'/>
    <jello name='jelloname' href='http://jello.com'/>
    <subelement>
      <jello name='subjelloname' href='http://ohnojello.com' other='othertext'/>
    </subelement>
  </root>      
}

module GenericBase
  class Base
    include HappyMapper
    tag '*'
    attribute :name, String
    attribute :href, String
    attribute :other, String
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


describe HappyMapper do
  describe "can have generic classes using tag '*'" do
      
    before(:all) do
      @root = GenericBase::Root.parse(generic_class_xml)
      @xml = Nokogiri::XML(@root.to_xml)   
    end
    
    it 'should map different elements to same class' do
      @root.blargs.should_not be_nil
      @root.jellos.should_not be_nil
    end
    
    it 'should filter on xpath appropriately' do
      @root.blargs.should have(2).items
      @root.jellos.should have(1).items
      @root.subjellos.should have(1).items
    end
     
    it 'should parse correct values onto generic class' do
      @root.blargs[0].name.should == 'blargname1'
      @root.blargs[0].href.should == 'http://blarg.com'
      @root.blargs[0].other.should be_nil
      @root.blargs[1].name.should == 'blargname2'
      @root.blargs[1].href.should == 'http://blarg.com'
      @root.blargs[1].other.should be_nil
      @root.jellos[0].name.should == 'jelloname'
      @root.jellos[0].href.should == 'http://jello.com'
      @root.jellos[0].other.should be_nil
      @root.subjellos[0].name.should == 'subjelloname'
      @root.subjellos[0].href.should == 'http://ohnojello.com'
      @root.subjellos[0].other.should == 'othertext'
    end

    it 'should #to_xml using parent element tag name' do      
      @xml.xpath('/root/description').text.should == 'some description'
      @xml.xpath('/root/blarg[1]/@name').text.should == 'blargname1'
      @xml.xpath('/root/blarg[1]/@href').text.should == 'http://blarg.com'
      @xml.xpath('/root/blarg[1]/@other').text.should be_empty
      @xml.xpath('/root/blarg[2]/@name').text.should == 'blargname2'
      @xml.xpath('/root/blarg[2]/@href').text.should == 'http://blarg.com'
      @xml.xpath('/root/blarg[2]/@other').text.should be_empty
      @xml.xpath('/root/jello[1]/@name').text.should == 'jelloname'
      @xml.xpath('/root/jello[1]/@href').text.should == 'http://jello.com'
      @xml.xpath('/root/jello[1]/@other').text.should be_empty  
    end
    
    it "should properly respect child HappyMapper tags if tag isn't provided on the element defintion" do
      @xml.xpath('root/subelement').should have(1).item
    end
  end                   
end
