require 'spec/spec_helper'

describe "The default option of attributes" do

  class WithDefault
    include HappyMapper
    tag 'foo'
    attribute :bar, String, :default => 'baz'
  end

  it 'should return the default value after parsing a string without it' do
    foo = WithDefault.parse('<foo />')
    foo.bar.should == 'baz'
  end

  it 'should not include the default value in the produced xml' do
    foo = WithDefault.new
    foo.to_xml.should == %{<?xml version="1.0"?>\n<foo/>\n}
  end

  it 'should not return the default value when a non-nil value has been set' do
    foo = WithDefault.parse('<foo />')
    foo.bar = 'not-baz'
    foo.bar.should_not == 'baz'
  end

  it 'should include a non-nil value in the XML' do
    foo = WithDefault.new
    foo.bar = 'not-baz'
    foo.to_xml.should == %{<?xml version="1.0"?>\n<foo bar="not-baz"/>\n}
  end
end