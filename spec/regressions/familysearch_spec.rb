# frozen_string_literal: true

require "spec_helper"

RSpec.describe "parsing a familysearch family tree" do
  before do
    alternateids_klass = Class.new do
      include HappyMapper

      tag "alternateIds"
      has_many :ids, String, tag: "id"
    end
    stub_const "AlternateIds", alternateids_klass

    information_klass = Class.new do
      include HappyMapper

      has_one :alternateIds, AlternateIds
    end
    stub_const "Information", information_klass

    person_klass = Class.new do
      include HappyMapper

      attribute :version, String
      attribute :modified, Time
      attribute :id, String
      has_one :information, Information
    end
    stub_const "Person", person_klass

    persons_klass = Class.new do
      include HappyMapper
      has_many :person, Person
    end
    stub_const "Persons", persons_klass

    familytree_klass = Class.new do
      include HappyMapper

      tag "familytree"
      attribute :version, String
      attribute :status_message, String, tag: "statusMessage"
      attribute :status_code, String, tag: "statusCode"
      has_one :persons, Persons
    end
    stub_const "FamilyTree", familytree_klass
  end

  it "parses family search xml correctly" do
    tree = FamilyTree.parse(fixture_file("family_tree.xml"))

    aggregate_failures do
      expect(tree.version).to eq("1.0.20071213.942")
      expect(tree.status_message).to eq("OK")
      expect(tree.status_code).to eq("200")
      expect(tree.persons.person.size).to eq(1)
      expect(tree.persons.person.first.version).to eq("1199378491000")
      expect(tree.persons.person.first.modified)
        .to eq(Time.utc(2008, 1, 3, 16, 41, 31)) # 2008-01-03T09:41:31-07:00
      expect(tree.persons.person.first.id).to eq("KWQS-BBQ")
      expect(tree.persons.person.first.information.alternateIds.ids).not_to be_a(String)
      expect(tree.persons.person.first.information.alternateIds.ids.size).to eq(8)
    end
  end
end
