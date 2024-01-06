# frozen_string_literal: true

require "spec_helper"

class ParserTest
  include HappyMapper

  class Coerce
    def self.number_list(val)
      val.to_s.split(",").map { _1.strip.to_i }
    end
  end

  tag "parsertest"
  attribute :numbers, Coerce, parser: :number_list
  element :strings, self, parser: :string_list
  element :bool, String, parser: ->(val) { val.to_s == "1" }

  def self.string_list(val)
    val.to_s.split(",").map(&:strip)
  end
end

RSpec.describe "specifying a custom parser for attributes and elements" do
  let(:xml) do
    <<~XML
      <parsertest numbers="1,2,3">
        <strings>a, b, c</strings>
        <bool>0</bool>
      </parsertest>
    XML
  end

  it "parses with a singleton method on the type class" do
    parsed = ParserTest.parse xml

    expect(parsed.numbers).to eq [1, 2, 3]
  end

  it "parses with a singleton method on the model class" do
    parsed = ParserTest.parse xml

    expect(parsed.strings).to eq %w(a b c)
  end

  it "parses with a proc specified in the element definition" do
    parsed = ParserTest.parse xml

    expect(parsed.bool).to be false
  end
end
