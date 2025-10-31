# frozen_string_literal: true

require "spec_helper"

RSpec.describe HappyMapper::ClassMethods do
  let(:klass) do
    Class.new.tap do |cls|
      cls.extend described_class
    end
  end

  describe "#tag" do
    it "does not allow namespace to be included" do
      expect { klass.tag "foo:bar" }.to raise_error HappyMapper::SyntaxError
    end
  end

  describe "#namespace" do
    it "allows string values" do
      klass.namespace "foo"
      expect(klass.namespace).to eq "foo"
    end

    it "converts symbol values to string" do
      klass.namespace :foo
      expect(klass.namespace).to eq "foo"
    end
  end
end
