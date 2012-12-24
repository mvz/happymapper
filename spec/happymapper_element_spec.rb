require File.dirname(__FILE__) + '/spec_helper.rb'

describe HappyMapper::Element do
  describe "initialization" do
    before do
      @attr = HappyMapper::Element.new(:foo, String)
    end
  end
end
