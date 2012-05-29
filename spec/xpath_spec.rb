require File.dirname(__FILE__) + '/spec_helper.rb'

test_xml = %{
  <rss>
    <amazing:item xmlns:amazing="http://www.amazing.com/amazing" xmlns:different="http://www.different.com/different">
      <amazing:title>Test XML</amazing:title>
      <different:link href="different_link" />
      <amazing:link href="link_to_resources" />
      <amazing:subitem>
        <amazing:detail>I want to parse this</amazing:detail>
        <amazing:more first="this one">more 1</amazing:more>
        <amazing:more alternative="another one">more 2</amazing:more>
      </amazing:subitem>
      <amazing:baby>
        <amazing:name>Jumbo</amazing:name>
      </amazing:baby>
    </amazing:item>
  </rss>
}

class Item
  include HappyMapper

  tag 'item'
  namespace 'amazing'

  element :title, String
  attribute :link, String, :xpath => 'amazing:link/@href'
  has_one :different_link, String, :xpath => 'different:link/@href'
  element :detail, String, :xpath => 'amazing:subitem/amazing:detail'
  has_many :more_details_text, String, :xpath => 'amazing:subitem/amazing:more'
  has_many :more_details, String, :xpath => 'amazing:subitem/amazing:more/@first|amazing:subitem/amazing:more/@alternative'
  has_many :more_details_alternative, String, :xpath => 'amazing:subitem/amazing:more/@*'

  has_one :baby, 'Baby', :name => 'baby', :namespace => 'amazing'

end

class Baby
  include HappyMapper

  has_one :name, String
end

describe HappyMapper do

  it "should have a title" do
    @item.title.should == "Test XML"
  end

  it "should find the link href value" do
    @item.link.should == 'link_to_resources'
  end

  it "should find the link href value" do
    @item.different_link.should == 'different_link'
  end

  it "should find this subitem based on the xpath" do
    @item.detail.should == 'I want to parse this'
  end

  it "should find the subitems based on the xpath" do
    @item.more_details_text.length.should == 2
    @item.more_details_text.first.should == "more 1"
    @item.more_details_text.last.should == "more 2"
  end

  it "should find the subitems based on the xpath" do
    @item.more_details.length.should == 2
    @item.more_details.first.should == "this one"
    @item.more_details.last.should == "another one"
  end

  it "should find the subitems based on the xpath" do
    @item.more_details.length.should == 2
    @item.more_details_alternative.first.should == "this one"
    @item.more_details_alternative.last.should == "another one"
  end
  it "should have a baby name" do
    @item.baby.name.should == "Jumbo"
  end

  before(:all) do
    @item = Item.parse(test_xml,:single => true)
  end

end
