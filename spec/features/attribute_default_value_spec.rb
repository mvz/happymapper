# frozen_string_literal: true

require "spec_helper"

class Meal
  include HappyMapper
  tag "meal"
  attribute :type, String, default: "omnivore"
end

RSpec.describe "Attribute Default Value" do
  context "when given a default value" do
    let(:default_meal_type) { "omnivore" }

    context "when no value has been specified" do
      it "returns the default value" do
        meal = Meal.parse("<meal />")
        expect(meal.type).to eq default_meal_type
      end
    end

    context "when saving to xml" do
      let(:expected_xml) { %(<?xml version="1.0"?>\n<meal/>\n) }

      it "the default value is not included" do
        meal = Meal.new
        expect(meal.to_xml).to eq expected_xml
      end
    end

    context "when a new, non-nil value has been set" do
      let(:expected_xml) { %(<?xml version="1.0"?>\n<meal type="kosher"/>\n) }

      it "returns the new value" do
        meal = Meal.parse("<meal />")
        meal.type = "vegan"

        expect(meal.type).not_to eq default_meal_type
      end

      it "saves the new value to the xml" do
        meal = Meal.new
        meal.type = "kosher"
        expect(meal.to_xml).to eq expected_xml
      end
    end
  end
end
