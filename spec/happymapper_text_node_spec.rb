require File.dirname(__FILE__) + '/spec_helper.rb'

describe HappyMapper::Attribute do
  describe "initialization" do
    before do
      @attr = HappyMapper::TextNode.new(:foo, String)
    end
  end
end
