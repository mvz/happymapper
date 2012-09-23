require File.dirname(__FILE__) + '/spec_helper.rb'

parse_instance_initial_xml = %{
  <root attr1="initial">
    <item attr1="initial">
      <description>initial</description>
      <subitem attr1="initial">
        <name>initial</name>
      </subitem>
      <subitem attr1="initial">
        <name>initial</name>
      </subitem>
    </item>
    <item attr1="initial">
      <description>initial</description>
      <subitem attr1="initial">
        <name>initial</name>
      </subitem>
      <subitem attr1="initial">
        <name>initial</name>
      </subitem>
    </item>
  </root>
}

parse_instance_updated_xml = %{
  <root attr1="updated">
    <item attr1="updated">
      <description>updated</description>
      <subitem attr1="updated">
        <name>updated</name>
      </subitem>
      <subitem attr1="updated">
        <name>updated</name>
      </subitem>
    </item>
    <item attr1="updated">
      <description>updated</description>
      <subitem attr1="updated">
        <name>updated</name>
      </subitem>
      <subitem attr1="updated">
        <name>updated</name>
      </subitem>
    </item>
  </root>
}

module ParseInstanceSpec
  class SubItem
    include HappyMapper
    tag 'subitem'
    attribute :attr1, String
    element :name, String
  end
  class Item
    include HappyMapper
    tag 'item'
    attribute :attr1, String
    element :description, String
    has_many :sub_items, SubItem
  end
  class Root
    include HappyMapper
    tag 'root'
    attribute :attr1, String
    has_many :items, Item
  end
end

describe HappyMapper do
  describe "update existing instance by parsing new xml" do
    
    it 'should have initial values' do
      @initial.attr1.should == 'initial'
      @initial.items[0].attr1.should == 'initial'
      @initial.items[0].description.should == 'initial'
      @initial.items[0].sub_items[0].attr1.should == 'initial'
      @initial.items[0].sub_items[0].name.should == 'initial'
      @initial.items[0].sub_items[1].attr1.should == 'initial'
      @initial.items[0].sub_items[1].name.should == 'initial'
      @initial.items[1].attr1.should == 'initial'
      @initial.items[1].description.should == 'initial'
      @initial.items[1].sub_items[0].attr1.should == 'initial'
      @initial.items[1].sub_items[0].name.should == 'initial'
      @initial.items[1].sub_items[1].attr1.should == 'initial'
      @initial.items[1].sub_items[1].name.should == 'initial'
    end
    
    it 'should have updated values' do
      ParseInstanceSpec::Root.parse(parse_instance_updated_xml, :update => @initial)
      @initial.attr1.should == 'updated'
      @initial.items[0].attr1.should == 'updated'
      @initial.items[0].description.should == 'updated'
      @initial.items[0].sub_items[0].attr1.should == 'updated'
      @initial.items[0].sub_items[0].name.should == 'updated'
      @initial.items[0].sub_items[1].attr1.should == 'updated'
      @initial.items[0].sub_items[1].name.should == 'updated'
      @initial.items[1].attr1.should == 'updated'
      @initial.items[1].description.should == 'updated'
      @initial.items[1].sub_items[0].attr1.should == 'updated'
      @initial.items[1].sub_items[0].name.should == 'updated'
      @initial.items[1].sub_items[1].attr1.should == 'updated'
      @initial.items[1].sub_items[1].name.should == 'updated'
    end
    
    it "should be able to update instance from 'parse()' instance method" do 
      @initial.parse(parse_instance_updated_xml)
      @initial.attr1.should == 'updated'
      @initial.items[0].attr1.should == 'updated'
      @initial.items[0].description.should == 'updated'
      @initial.items[0].sub_items[0].attr1.should == 'updated'
      @initial.items[0].sub_items[0].name.should == 'updated'
      @initial.items[0].sub_items[1].attr1.should == 'updated'
      @initial.items[0].sub_items[1].name.should == 'updated'
      @initial.items[1].attr1.should == 'updated'
      @initial.items[1].description.should == 'updated'
      @initial.items[1].sub_items[0].attr1.should == 'updated'
      @initial.items[1].sub_items[0].name.should == 'updated'
      @initial.items[1].sub_items[1].attr1.should == 'updated'
      @initial.items[1].sub_items[1].name.should == 'updated'
    end
    
    before(:each) do
      @initial = ParseInstanceSpec::Root.parse(parse_instance_initial_xml)
    end
  end
end

