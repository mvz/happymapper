# frozen_string_literal: true

require 'spec_helper'

module AttributeMethodConversion
  class Document
    include HappyMapper

    has_many :link, String, attributes: { 'data-src': String, type: String, href: String }
    has_one :class, String
  end
end

RSpec.describe 'Attribute Method Conversion', type: :feature do
  let(:xml_document) do
    %(<document>
        <link data-src='http://cooking.com/roastbeef' type='recipe'>Roast Beef</link>
      </document>)
  end

  let(:document) do
    AttributeMethodConversion::Document.parse(xml_document, single: true)
  end

  it 'link' do
    expect(document.link).to eq ['Roast Beef']
  end

  it 'link.data_src' do
    expect(document.link.first.data_src).to eq 'http://cooking.com/roastbeef'
  end

  it 'link.type' do
    expect(document.link.first.type).to eq 'recipe'
  end
end
