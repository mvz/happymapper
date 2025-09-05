# frozen_string_literal: true

require "spec_helper"

RSpec.describe "parsing a VOD catalog" do
  before do
    catalog_tree = Class.new do
      include HappyMapper

      tag "CatalogTree"
      register_namespace "xmlns", "urn:eventis:prodis:onlineapi:1.0"
      register_namespace "xsi", "http://www.w3.org/2001/XMLSchema-instance"
      register_namespace "xsd", "http://www.w3.org/2001/XMLSchema"

      attribute :code, String

      has_many :nodes, "CatalogNode", tag: "Node", xpath: "."
    end
    stub_const "CatalogTree", catalog_tree

    catalog_node = Class.new do
      include HappyMapper

      tag "Node"

      attribute :back_office_id, String, tag: "vodBackOfficeId"

      has_one :name, String, tag: "Name"
      # other important fields

      has_many :translations, "CatalogNode::Translations", tag: "Translation",
                                                           xpath: "child::*"

      has_many :nodes, self, tag: "Node", xpath: "child::*"
    end
    stub_const "CatalogNode", catalog_node

    translations = Class.new do
      include HappyMapper

      tag "Translation"

      attribute :language, String, tag: "Language"
      has_one :name, String, tag: "Name"
    end
    stub_const "CatalogNode::Translations", translations
  end

  let(:catalog_tree) { CatalogTree.parse(fixture_file("inagy.xml"), single: true) }

  it "is not nil" do
    expect(catalog_tree).not_to be_nil
  end

  it "has the attribute code" do
    expect(catalog_tree.code).to eq("NLD")
  end

  it "has many nodes" do
    nodes = catalog_tree.nodes

    aggregate_failures do
      expect(nodes).not_to be_empty
      expect(nodes.length).to eq(2)
    end
  end

  describe "first node" do
    let(:first_node) { catalog_tree.nodes.first }

    it "has a name" do
      expect(first_node.name).to eq("Parent 1")
    end

    it "has translations" do
      translations = first_node.translations

      aggregate_failures do
        expect(translations.length).to eq(2)
        expect(translations.first.language).to eq("en-GB")
        expect(translations.last.name).to eq("Parent 1 de")
      end
    end

    it "has subnodes" do
      nodes = first_node.nodes

      aggregate_failures do
        expect(nodes).to be_a(Enumerable)
        expect(nodes).not_to be_empty
        expect(nodes.length).to eq(1)
      end
    end

    it "first node - first node name" do
      expect(first_node.nodes.first.name).to eq("First")
    end
  end
end
