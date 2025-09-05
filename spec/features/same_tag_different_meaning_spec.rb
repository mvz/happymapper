# frozen_string_literal: true

require "spec_helper"

module SameTagSpec
  class Bar
    include HappyMapper

    has_one :baz, String
  end

  class Baz
    include HappyMapper

    has_one :qux, String
  end

  class Foo
    include HappyMapper

    has_one :bar, Bar
    has_one :baz, Baz, xpath: "."
  end
end

RSpec.describe "parsing the same tag differently in different contexts" do
  let(:xml) do
    <<~XML
      <foo>
        <bar>
          <baz>Hello</baz>
        </bar>
        <baz>
          <qux>Hi</qux>
        </baz>
      </foo>
    XML
  end

  it "parses both uses correctly if xpath limits recursion" do
    result = SameTagSpec::Foo.parse xml
    aggregate_failures do
      expect(result.bar.baz).to eq "Hello"
      expect(result.baz.qux).to eq "Hi"
    end
  end
end
