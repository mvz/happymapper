# frozen_string_literal: true

require "spec_helper"

RSpec.describe "parsing github commit xml" do
  before do
    commit_klass = Class.new do
      include HappyMapper

      tag "commit"
      element :url, String
      element :tree, String
      element :message, String
      element :id, String
      element :"committed-date", Date
    end
    stub_const "Commit", commit_klass
  end

  it "parses xml that has elements with dashes" do
    commit = Commit.parse(fixture_file("commit.xml"))

    aggregate_failures do
      expect(commit.message).to eq("move commands.rb and helpers.rb into commands/ dir")
      expect(commit.url).to eq("http://github.com/defunkt/github-gem/commit/c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b")
      expect(commit.id).to eq("c26d4ce9807ecf57d3f9eefe19ae64e75bcaaa8b")
      expect(commit.committed_date).to eq(Date.parse("2008-03-02T16:45:41-08:00"))
      expect(commit.tree).to eq("28a1a1ca3e663d35ba8bf07d3f1781af71359b76")
    end
  end
end
