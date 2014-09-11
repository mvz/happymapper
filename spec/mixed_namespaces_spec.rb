require 'spec_helper'

describe "A document with mixed namespaces" do

  #
  # Note that the parent element of the xml has the namespacing. The elements
  # contained within the xml do not share the parent element namespace so a
  # user of the library would likely need to clear the namespace on each of
  # these child elements.
  #
  let(:xml_document) do
    %{<prefix:address location='home' xmlns:prefix="http://www.unicornland.com/prefix"
        xmlns:different="http://www.trollcountry.com/different">
        <street>Milchstrasse</street>
        <street>Another Street</street>
        <housenumber>23</housenumber>
        <different:postcode>26131</different:postcode>
        <city>Oldenburg</city>
      </prefix:address>}
  end

  module MixedNamespaces
    class Address
      include HappyMapper

      namespace :prefix
      tag :address

      # Here each of the elements have their namespace set to nil to reset their
      # namespace so that it is not the same as the prefix namespace

      has_many :streets, String, :tag => 'street', :namespace => nil

      has_one :house_number, String, :tag => 'housenumber', :namespace => nil
      has_one :postcode, String, :namespace => 'different'
      has_one :city, String, :namespace => nil
    end
  end

  let(:address) do
    MixedNamespaces::Address.parse(xml_document, :single => true)
  end


  it "has the correct streets" do
    expect(address.streets).to eq [ "Milchstrasse", "Another Street" ]
  end

  it "house number" do
    expect(address.house_number).to eq "23"
  end

  it "postcode" do
    expect(address.postcode).to eq "26131"
  end

  it "city" do
    expect(address.city).to eq "Oldenburg"
  end

end
