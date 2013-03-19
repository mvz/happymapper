require 'spec_helper'

describe "Saving #to_xml" do

  module ToXML
    class Address
      include HappyMapper

      tag 'address'

      attribute :location, String, :on_save => :when_saving_location

      element :street, String
      element :postcode, String
      element :city, String

      element :housenumber, String

      attribute :modified, Boolean, :read_only => true
      element :temporary, Boolean, :read_only => true
      #
      # to_xml will default to the attr_accessor method and not the attribute,
      # allowing for that to be overwritten
      #
      def housenumber
        "[#{@housenumber}]"
      end

      def when_saving_location(loc)
        loc + "-live"
      end

      #
      # Write a empty element even if this is not specified
      #
      element :description, String, :state_when_nil => true

      #
      # Perform the on_save operation when saving
      #
      has_one :date_created, Time, :on_save => lambda {|time| DateTime.parse(time).strftime("%T %D") if time }


      #
      # Execute the method with the same name

      #
      # Write multiple elements and call on_save when saving
      #
      has_many :dates_updated, Time, :on_save => lambda {|times|
        times.compact.map {|time| DateTime.parse(time).strftime("%T %D") } if times }

      #
      # Class composition
      #
      element :country, 'Country', :tag => 'country'

      attribute :occupied, Boolean

      def initialize(parameters)
        parameters.each_pair do |property,value|
          send("#{property}=",value) if respond_to?("#{property}=")
        end
        @modified = @temporary = true
      end

    end

    #
    # Country is composed above the in Address class. Here is a demonstration
    # of how to_xml will handle class composition as well as utilizing the tag
    # value.
    #
    class Country
      include HappyMapper

      attribute :code, String, :tag => 'countryCode'
      has_one :name, String, :tag => 'countryName'
      has_one :description, 'Description', :tag => 'description'

      #
      # This inner-class here is to demonstrate saving a text node
      # and optional attributes
      #
      class Description
        include HappyMapper
        content :description, String
        attribute :category, String, :tag => 'category'
        attribute :rating, String, :tag => 'rating', :state_when_nil => true

        def initialize(desc)
          @description = desc
        end
      end

      def initialize(parameters)
        parameters.each_pair do |property,value|
          send("#{property}=",value) if respond_to?("#{property}=")
        end
      end

    end
  end

  let(:subject) do
    address = ToXML::Address.new 'street' => 'Mockingbird Lane',
      'location' => 'Home',
      'housenumber' => '1313',
      'postcode' => '98103',
      'city' => 'Seattle',
      'country' => ToXML::Country.new(:name => 'USA', :code => 'us', :empty_code => nil,
        :description => ToXML::Country::Description.new("A lovely country") ),
      'date_created' => '2011-01-01 15:00:00',
      'occupied' => false

    address.dates_updated = ["2011-01-01 16:01:00","2011-01-02 11:30:01"]

    Nokogiri::XML(address.to_xml).root
  end

  it "saves elements" do
    elements = { 'street' => 'Mockingbird Lane', 'postcode' => '98103', 'city' => 'Seattle' }
    elements.each_pair do |property,value|
      expect(subject.xpath("#{property}").text).to eq value
    end
  end

  it "saves attributes" do
    expect(subject.xpath('@location').text).to eq "Home-live"
  end

  it 'saves attributes that are Boolean and have a value of false' do
    expect(subject.xpath('@occupied').text).to eq "false"
  end

  context "when an element has a 'read_only' parameter" do
    it "does not save elements" do
      expect(subject.xpath('temporary')).to be_empty
    end
  end

  context "when an attribute has a 'read_only' parameter" do
    it "does not save attributes" do
      expect(subject.xpath("@modified")).to be_empty
    end
  end

  context "when an element has a 'state_when_nil' parameter" do
    it "saves an empty element" do
      expect(subject.xpath('description').text).to eq ""
    end
  end

  context "when an element has a 'on_save' parameter" do
    context "with a symbol which represents a function" do
      it "saves the element with the result of the function" do
        expect(subject.xpath("housenumber").text).to eq "[1313]"
      end
    end

    context "with a lambda" do
      it "saves the result of the lambda" do
        expect(subject.xpath('date_created').text).to eq "15:00:00 01/01/11"
      end
    end
  end

  context "when a has_many has a 'on_save' parameter" do
    context "with a lambda" do
      it "saves the results" do
        dates_updated = subject.xpath('dates_updated')
        expect(dates_updated.length).to eq 2
        expect(dates_updated.first.text).to eq "16:01:00 01/01/11"
        expect(dates_updated.last.text).to eq "11:30:01 01/02/11"
      end
    end
  end

  context "when an attribute has a 'on_save' parameter" do
    context "with a symbol which represents a function" do
      it "saves the result" do
        expect(subject.xpath('@location').text).to eq "Home-live"
      end
    end
  end

  context "when an element type is a HappyMapper subclass" do
    it "saves attributes" do
      expect(subject.xpath('country/@countryCode').text).to eq "us"
    end

    it "saves elements" do
      expect(subject.xpath('country/countryName').text).to eq "USA"
    end

    it "saves elements" do
      expect(subject.xpath('country/description').text).to eq "A lovely country"
    end
  end
end