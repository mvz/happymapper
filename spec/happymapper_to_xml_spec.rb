require File.dirname(__FILE__) + '/spec_helper.rb'

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

  describe HappyMapper do

    context "#to_xml" do
      
      before(:all) do
        address = Address.new('street' => 'Mockingbird Lane',
        'location' => 'Home',
        'housenumber' => '1313',
        'postcode' => '98103',
        'city' => 'Seattle',
        'country' => Country.new(:name => 'USA', :code => 'us', :empty_code => nil, 
          :description => Country::Description.new("A lovely country") ),
        'date_created' => '2011-01-01 15:00:00',
        'occupied' => false)
        
        
        address.dates_updated = ["2011-01-01 16:01:00","2011-01-02 11:30:01"]
        
        @address_xml = Nokogiri::XML(address.to_xml).root
      end
      
      it "should save elements" do
        { 'street' => 'Mockingbird Lane',
          'postcode' => '98103',
          'city' => 'Seattle' }.each_pair do |property,value|
        
          @address_xml.xpath("#{property}").text.should == value
          
        end
      end
      
      it "should save the element with the result of a function call and not the value of the instance variable" do
        @address_xml.xpath("housenumber").text.should == "[1313]"
      end
      
      it "should not save elements marked as read_only" do
        @address_xml.xpath('temporary').should be_empty
      end
      
      it "should save attribues" do
        @address_xml.xpath('@location').text.should == "Home-live"
      end
      
      it "should not save attributes marked as read_only" do
        @address_xml.xpath("@modified").should be_empty
      end
      
      it 'should save attributes that are Boolean and have a value of false' do
        @address_xml.xpath('@occupied').text.should == "false"
      end
      
      context "state_when_nil option" do
      
        it "should save an empty element" do
          @address_xml.xpath('description').text.should == ""
        end
        
      end

      context "on_save option" do
        
        it "should save the result of the lambda" do
          @address_xml.xpath('date_created').text.should == "15:00:00 01/01/11"
        end
        
        it "should save the result of a method" do
          @address_xml.xpath('@location').text.should == "Home-live"
        end
        
      end

      
      it "should save elements defined with the 'has_many' relationship" do
        dates_updated = @address_xml.xpath('dates_updated')
        dates_updated.length.should == 2
        dates_updated.first.text.should == "16:01:00 01/01/11"
        dates_updated.last.text.should == "11:30:01 01/02/11"
      end

      context "class types that also contain HappyMapper mappings" do

        it "should save attributes" do
          @address_xml.xpath('country/@countryCode').text.should == "us"
        end

        it "should save elements" do
          @address_xml.xpath('country/countryName').text.should == "USA"
        end

        it "should save elements" do
          @address_xml.xpath('country/description').text.should == "A lovely country"
        end
        
      end

    end


  end

end
