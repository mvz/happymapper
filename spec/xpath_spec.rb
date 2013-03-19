require 'spec_helper'

describe "Specifying elements and attributes with an xpath" do

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

  let(:subject) { Item.parse(xml_string,:single => true) }

  let(:xml_string) do
    %{
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
  end

  it "should have a title" do
    expect(subject.title).to eq "Test XML"
  end

  it "should find the link href value" do
    expect(subject.link).to eq 'link_to_resources'
  end

  it "should find the link href value" do
    expect(subject.different_link).to eq 'different_link'
  end

  it "should find this subitem based on the xpath" do
    expect(subject.detail).to eq 'I want to parse this'
  end

  it "should find the subitems based on the xpath" do
    expect(subject.more_details_text).to have(2).items
    expect(subject.more_details_text.first).to eq  "more 1"
    expect(subject.more_details_text.last).to eq "more 2"
  end

  it "should find the subitems based on the xpath" do
    expect(subject.more_details).to have(2).items
    expect(subject.more_details.first).to eq "this one"
    expect(subject.more_details.last).to eq "another one"
  end

  it "should find the subitems based on the xpath" do
    expect(subject.more_details_alternative).to have(2).items
    expect(subject.more_details_alternative.first).to eq "this one"
    expect(subject.more_details_alternative.last).to eq "another one"
  end

  it "should have a baby name" do
    expect(subject.baby.name).to eq "Jumbo"
  end

end
