require 'spec_helper'

describe HappyMapper::Attribute do

  describe "initialization" do
    it 'accepts :default option' do
      attr = described_class.new(:foo, String, :default => 'foobar')
      expect(attr.default).to eq('foobar')
    end
  end

end
