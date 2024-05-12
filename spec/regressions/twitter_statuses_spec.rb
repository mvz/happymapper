# frozen_string_literal: true

require "spec_helper"

RSpec.describe "parsing twitter statuses" do
  before do
    user_klass = Class.new do
      include HappyMapper

      element :id, Integer
      element :name, String
      element :screen_name, String
      element :location, String
      element :description, String
      element :profile_image_url, String
      element :url, String
      element :protected, HappyMapper::Boolean
      element :followers_count, Integer
    end
    stub_const "User", user_klass

    status_klass = Class.new do
      include HappyMapper

      register_namespace "fake", "faka:namespace"

      element :id, Integer
      element :text, String
      element :created_at, Time
      element :source, String
      element :truncated, HappyMapper::Boolean
      element :in_reply_to_status_id, Integer
      element :in_reply_to_user_id, Integer
      element :favorited, HappyMapper::Boolean
      element :non_existent, String, tag: "dummy", namespace: "fake"
      has_one :user, User
    end
    stub_const "Status", status_klass
  end

  it "parses xml elements to ruby objects" do
    statuses = Status.parse(fixture_file("statuses.xml"))

    aggregate_failures do
      expect(statuses.size).to eq(20)
      first = statuses.first
      expect(first.id).to eq(882_281_424)
      expect(first.created_at).to eq(Time.utc(2008, 8, 9, 5, 38, 12))
      expect(first.source).to eq("web")
      expect(first.truncated).to be_falsey
      expect(first.in_reply_to_status_id).to eq(1234)
      expect(first.in_reply_to_user_id).to eq(12_345)
      expect(first.favorited).to be_falsey
      expect(first.user.id).to eq(4243)
      expect(first.user.name).to eq("John Nunemaker")
      expect(first.user.screen_name).to eq("jnunemaker")
      expect(first.user.location).to eq("Mishawaka, IN, US")
      expect(first.user.description)
        .to eq "Loves his wife, ruby, notre dame football and iu basketball"
      expect(first.user.profile_image_url)
        .to eq("http://s3.amazonaws.com/twitter_production/profile_images/53781608/Photo_75_normal.jpg")
      expect(first.user.url).to eq("http://addictedtonew.com")
      expect(first.user.protected).to be_falsey
      expect(first.user.followers_count).to eq(486)
    end
  end
end
