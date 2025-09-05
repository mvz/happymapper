# frozen_string_literal: true

module HappyMapper
  class AnonymousMapper
    def parse(xml_content)
      # TODO: this should be able to handle all the types of functionality that
      # parse is able to handle which includes the text, xml document, node,
      # fragment, etc.
      xml = Nokogiri::XML(xml_content)

      klass = create_happymapper_class_from_node(xml.root)

      # With all the elements and attributes defined on the class it is time
      # for the class to actually use the normal HappyMapper powers to parse
      # the content. At this point this code is utilizing all of the existing
      # code implemented for parsing.
      klass.parse(xml_content, single: true)
    end

    private

    #
    # Borrowed from Active Support to convert unruly element names into a format
    # known and loved by Rubyists.
    #
    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    #
    # Used internally when parsing to create a class that is capable of
    # parsing the content. The name of the class is of course not likely
    # going to match the content it will be able to parse so the tag
    # value is set to the one provided.
    #
    def create_happymapper_class_with_tag(tag_name)
      klass = Class.new
      klass.class_eval do
        include HappyMapper

        tag tag_name
      end
      klass
    end

    #
    # Used internally to create and define the necessary happymapper
    # elements.
    #
    def create_happymapper_class_from_node(node)
      klass = create_happymapper_class_with_tag(node.name)

      klass.namespace node.namespace.prefix if node.namespace

      node.namespaces.each do |prefix, namespace|
        klass.register_namespace prefix, namespace
      end

      node.attributes.each_value do |attribute|
        define_attribute_on_class(klass, attribute)
      end

      node.children.each do |child|
        define_element_on_class(klass, child)
      end

      klass
    end

    #
    # Define a HappyMapper element on the provided class based on
    # the node provided.
    #
    def define_element_on_class(klass, node)
      # When a text node has been provided create the necessary
      # HappyMapper content attribute if the text happens to contain
      # some content.

      if node.text?
        klass.content :content, String if node.content.strip != ""
        return
      end

      # When the node has child elements, that are not text
      # nodes, then we want to recursively define a new HappyMapper
      # class that will have elements and attributes.

      element_type = if node.elements.any? || node.attributes.any?
                       create_happymapper_class_from_node(node)
                     else
                       String
                     end

      element_name = underscore(node.name)
      method = klass.elements.find { |e| e.name == element_name } ? :has_many : :has_one

      options = {}
      options[:tag] = node.name
      namespace = node.namespace
      options[:namespace] = namespace.prefix if namespace
      options[:xpath] = "./" unless element_type == String

      klass.send(method, element_name, element_type, options)
    end

    #
    # Define a HappyMapper attribute on the provided class based on
    # the attribute provided.
    #
    def define_attribute_on_class(klass, attribute)
      klass.attribute underscore(attribute.name), String, tag: attribute.name
    end
  end
end
