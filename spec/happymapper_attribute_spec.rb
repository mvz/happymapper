require File.dirname(__FILE__) + '/spec_helper.rb'

describe HappyMapper::Attribute do
  describe "initialization" do
    before do
      @attr = HappyMapper::Attribute.new(:foo, String)
    end
    
    it 'should know that it is an attribute' do
      @attr.attribute?.should be_true
    end
    
    it 'should know that it is NOT an element' do
      @attr.element?.should be_false
    end

    it 'should know that it is NOT a text node' do
      @attr.text_node?.should be_false
    end

    it 'should accept :default as an option' do
      attr = described_class.new(:foo, String, :default => 'foobar')
      attr.default.should == 'foobar'
    end
  end
end
