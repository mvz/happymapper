# frozen_string_literal: true

require "spec_helper"

module AfterParseSpec
  class Address
    include HappyMapper

    element :street, String
  end
end

RSpec.describe "after_parse callbacks" do
  after do
    AfterParseSpec::Address.after_parse_callbacks.clear
  end

  it "calls back with the newly created object" do
    from_cb = nil
    called = false
    cb1 = proc { |object| from_cb = object }
    cb2 = proc { called = true }
    AfterParseSpec::Address.after_parse(&cb1)
    AfterParseSpec::Address.after_parse(&cb2)

    object = AfterParseSpec::Address.parse fixture_file("address.xml")

    aggregate_failures do
      expect(from_cb).to eq(object)
      expect(called).to be(true)
    end
  end
end
