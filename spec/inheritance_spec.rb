require 'spec_helper'

describe "inheritance of elements, attributes, etc. of HappyMapper classes" do

  class Elem
    include HappyMapper
  end

  class Parent
    include HappyMapper
    attribute :foo, String
    element :bar, Elem
  end

  class Child < Parent
    include HappyMapper
    attribute :quux, String
  end

  describe 'should behave as a Parent with an additional attribute quux' do
    it 'should be possible to serialize an instance of the Child class' do
      child = Child.new
      child.foo = 'something'
      child.quux = 'something_else'
      child.bar = Elem.new
      # A bit convoluted, because attribute order is not guaranteed in 1.8.7
      xml = child.to_xml
      xml.should include '<?xml version="1.0"?>'
      xml.should include 'quux="something_else"'
      xml.should include 'foo="something"'
      xml.should include "<elem\/>\n<\/child>\n"
    end

    it 'should be possible to deserialize XML into a Child class instance' do
      xml = '<child foo="something" quux="something_else"><elem/></child>'
      child = Child.parse(xml)
      child.foo.should == 'something'
      child.quux.should == 'something_else'
      child.bar.should be_a Elem
    end
  end
end
