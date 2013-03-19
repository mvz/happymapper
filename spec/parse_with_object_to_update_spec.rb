require 'spec_helper'

describe "Updating existing objects with .parse and #parse" do

  let(:subject) { ParseInstanceSpec::Root.parse(parse_instance_initial_xml) }

  let(:parse_instance_initial_xml) do
     %{<root attr1="initial">
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
    </root>}
  end

  let(:parse_instance_updated_xml) do
    %{<root attr1="updated">
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
    </root>}
  end

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

  def item_is_correctly_defined(item,value='initial')
    expect(item.attr1).to eq value
    expect(item.description).to eq value
    expect(item.sub_items[0].attr1).to eq value
    expect(item.sub_items[0].name).to eq value
    expect(item.sub_items[1].attr1).to eq value
    expect(item.sub_items[1].name).to eq value
  end

  it 'initial values are correct' do
    subject.attr1.should == 'initial'
    item_is_correctly_defined( subject.items[0] )
    item_is_correctly_defined( subject.items[1] )
  end


  describe ".parse", "specifying an existing object to update" do
    it 'all fields are correct' do
      ParseInstanceSpec::Root.parse(parse_instance_updated_xml, :update => subject)
      expect(subject.attr1).to eq 'updated'

      item_is_correctly_defined( subject.items[0], 'updated' )
      item_is_correctly_defined( subject.items[1], 'updated' )
    end
  end

  describe "#parse" do
    it "all fields are correct" do
      subject.parse(parse_instance_updated_xml)
      expect(subject.attr1).to eq 'updated'

      item_is_correctly_defined( subject.items[0], 'updated' )
      item_is_correctly_defined( subject.items[1], 'updated' )
    end
  end

end