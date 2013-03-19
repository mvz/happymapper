require 'spec_helper'

class CatalogTree
  include HappyMapper

  tag 'CatalogTree'
  register_namespace 'xmlns', 'urn:eventis:prodis:onlineapi:1.0'
  register_namespace 'xsi', 'http://www.w3.org/2001/XMLSchema-instance'
  register_namespace 'xsd', 'http://www.w3.org/2001/XMLSchema'

  attribute :code, String

  has_many :nodes, 'CatalogNode', :tag => 'Node', :xpath => '.'

end


class CatalogNode
  include HappyMapper

  tag 'Node'

  attribute :back_office_id, String, :tag => 'vodBackOfficeId'

  has_one :name, String, :tag => 'Name'
  # other important fields

  has_many :translations, 'CatalogNode::Translations', :tag => 'Translation', :xpath => 'child::*'

  class Translations
    include HappyMapper
    tag 'Translation'

    attribute :language, String, :tag => 'Language'
    has_one :name, String, :tag => 'Name'

  end

  has_many :nodes, CatalogNode, :tag => 'Node', :xpath => 'child::*'

end

describe HappyMapper do

  it "should not be nil" do
    catalog_tree.should_not be_nil
  end

  it "should have the attribute code" do
    catalog_tree.code.should == "NLD"
  end

  it "should have many nodes" do
    catalog_tree.nodes.should_not be_empty
    catalog_tree.nodes.length.should == 2
  end

  context "first node" do

    it "should have a name" do
      first_node.name.should == "Parent 1"
    end

    it "should have translations" do
      first_node.translations.length.should == 2

      first_node.translations.first.language.should == "en-GB"

      first_node.translations.last.name.should == "Parent 1 de"
    end

    it "should have subnodes" do
      first_node.nodes.should be_kind_of(Enumerable)
      first_node.nodes.should_not be_empty
      first_node.nodes.length.should == 1
    end

    it "first node - first node name" do
      first_node.nodes.first.name.should == "First"
    end

    def first_node
      @first_node = catalog_tree.nodes.first
    end

  end


  def catalog_tree ; @catalog_tree ; end

  before(:all) do
    xml_reference = "#{File.dirname(__FILE__)}/fixtures/inagy.xml"
    @catalog_tree = CatalogTree.parse(File.read(xml_reference), :single => true)
  end
end