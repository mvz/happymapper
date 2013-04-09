require File.dirname(__FILE__) + '/spec_helper.rb'

describe HappyMapper do

  context ".parse" do

    context "on a single root node" do

      subject { described_class.parse fixture_file('address.xml') }

      it "should parse child elements" do
        subject.street.should == "Milchstrasse"
        subject.housenumber.should == "23"
        subject.postcode.should == "26131"
        subject.city.should == "Oldenburg"
      end

      it "should not create a content entry when the xml contents no text content" do
        subject.should_not respond_to :content
      end

      context "child elements with attributes" do

        it "should parse the attributes" do
          subject.country.code.should == "de"
        end

        it "should parse the content" do
          subject.country.content.should == "Germany"
        end

      end

    end

    context "element names with special characters" do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it "should create accessor methods with similar names" do
        subject.my_items.item.should be_kind_of Array
      end
    end

    context "element names with camelCased elements and Capital Letters" do

      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it "should parse the elements an values correctly" do
        subject.title.should == "article title"
        subject.photo.publish_options.author.should == "Stephanie"
        subject.gallery.photo.title.should == "photo title"
      end
    end

    context "several elements nested deep" do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it "should parse the entire relationship" do
        subject.my_items.item.first.item.name.should == "My first internal item"
      end
    end

    context "xml that contains multiple entries" do

      subject { described_class.parse fixture_file('multiple_primitives.xml') }

      it "should parse the elements as it would a 'has_many'" do

        subject.name.should == "value"
        subject.image.should == [ "image1", "image2" ]

      end
      
    end

    context "xml with multiple namespaces" do

      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it "should parse the elements an values correctly" do
        subject.title.should == "article title"
      end
    end

  end

end