require 'spec_helper'

describe HappyMapper::Element do
  describe "initialization" do
    before do
      @attr = HappyMapper::Element.new(:foo, String)
    end
  end
end
