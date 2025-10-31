# frozen_string_literal: true

require "nokogiri"
require "date"
require "time"
require "happymapper/version"
require "happymapper/anonymous_mapper"
require "happymapper/class_methods"

module HappyMapper
  class Boolean; end

  class XmlContent; end

  def self.parse(xml_content)
    AnonymousMapper.new.parse(xml_content)
  end

  def self.included(base)
    if base.superclass <= HappyMapper
      base.instance_eval do
        @attributes =
          superclass.instance_variable_get(:@attributes).dup
        @elements =
          superclass.instance_variable_get(:@elements).dup
        @registered_namespaces =
          superclass.instance_variable_get(:@registered_namespaces).dup
        @wrapper_anonymous_classes =
          superclass.instance_variable_get(:@wrapper_anonymous_classes).dup
      end
    else
      base.instance_eval do
        @attributes = {}
        @elements = {}
        @registered_namespaces = {}
        @wrapper_anonymous_classes = {}
      end
    end

    base.extend ClassMethods
  end

  # Set all attributes with a default to their default values
  def initialize
    super
    self.class.attributes.reject { |attr| attr.default.nil? }.each do |attr|
      send(:"#{attr.method_name}=", attr.default)
    end
  end

  #
  # Create an xml representation of the specified class based on defined
  # HappyMapper elements and attributes. The method is defined in a way
  # that it can be called recursively by classes that are also HappyMapper
  # classes, allowg for the composition of classes.
  #
  # @param [Nokogiri::XML::Builder] builder an instance of the XML builder which
  #     is being used when called recursively.
  # @param [String] default_namespace The name of the namespace which is the
  #     default for the xml being produced; this is the namespace of the
  #     parent
  # @param [String] namespace_override The namespace specified with the element
  #     declaration in the parent. Overrides the namespace declaration in the
  #     element class itself when calling #to_xml recursively.
  # @param [String] tag_from_parent The xml tag to use on the element when being
  #     called recursively.  This lets the parent doc define its own structure.
  #     Otherwise the element uses the tag it has defined for itself.  Should only
  #     apply when calling a child HappyMapper element.
  #
  # @return [String,Nokogiri::XML::Builder] return XML representation of the
  #      HappyMapper object; when called recursively this is going to return
  #      and Nokogiri::XML::Builder object.
  #
  def to_xml(builder = nil, default_namespace = nil, namespace_override = nil,
             tag_from_parent = nil)
    #
    # If to_xml has been called without a passed in builder instance that
    # means we are going to return xml output. When it has been called with

    # a builder instance that means we most likely being called recursively
    # and will return the end product as a builder instance.
    #
    unless builder
      write_out_to_xml = true
      builder = Nokogiri::XML::Builder.new
    end

    attributes = collect_writable_attributes

    #
    # If the object we are serializing has a namespace declaration we will want
    # to use that namespace or we will use the default namespace.
    # When neither are specifed we are simply using whatever is default to the
    # builder
    #
    namespace_name = namespace_override || self.class.namespace || default_namespace

    #
    # Create a tag in the builder that matches the class's tag name unless a tag was passed
    # in a recursive call from the parent doc.  Then append
    # any attributes to the element that were defined above.
    #

    tag_name = tag_from_parent || self.class.tag_name
    builder.send(:"#{tag_name}_", attributes) do |xml|
      register_namespaces_with_builder(builder)

      xml.parent.namespace =
        builder.doc.root.namespace_definitions.find { |x| x.prefix == namespace_name }

      #
      # When a content has been defined we add the resulting value
      # the output xml
      #
      if (content = self.class.defined_content) && !content.options[:read_only]
        value = send(content.name)
        value = apply_on_save_action(content, value)

        builder.text(value)
      end

      #
      # for every define element (i.e. has_one, has_many, element) we are
      # going to persist each one
      #
      self.class.elements.each do |element|
        element_to_xml(element, xml, default_namespace)
      end
    end

    # Write out to XML, this value was set above, based on whether or not an XML
    # builder object was passed to it as a parameter. When there was no parameter
    # we assume we are at the root level of the #to_xml call and want the actual
    # xml generated from the object. If an XML builder instance was specified
    # then we assume that has been called recursively to generate a larger
    # XML document.
    write_out_to_xml ? builder.to_xml.force_encoding("UTF-8") : builder
  end

  # Parse the xml and update this instance. This does not update instances
  # of HappyMappers that are children of this object.  New instances will be
  # created for any HappyMapper children of this object.
  #
  # Params and return are the same as the class parse() method above.
  def parse(xml, options = {})
    self.class.parse(xml, options.merge!(update: self))
  end

  # Factory for creating anonmyous HappyMappers
  class AnonymousWrapperClassFactory
    def self.get(name, &blk)
      Class.new do
        include HappyMapper

        tag name
        instance_eval(&blk)
      end
    end
  end

  private

  #
  # If the item defines an on_save lambda/proc or value that maps to a method
  # that the class has defined, then call it with the value as a parameter.
  # This allows for operations to be performed to convert the value to a
  # specific value to be saved to the xml.
  #
  def apply_on_save_action(item, value)
    if (on_save_action = item.options[:on_save])
      if on_save_action.is_a?(Proc)
        value = on_save_action.call(value)
      elsif respond_to?(on_save_action)
        value = send(on_save_action, value)
      end
    end
    value
  end

  #
  # Find the attributes for the class and collect them into a Hash structure
  #
  def collect_writable_attributes
    #
    # Find the attributes for the class and collect them into an array
    # that will be placed into a Hash structure
    #
    attributes = self.class.attributes.filter_map do |attribute|
      #
      # If an attribute is marked as read_only then we want to ignore the attribute
      # when it comes to saving the xml document; so we will not go into any of
      # the below process
      #
      next if attribute.options[:read_only]

      value = send(attribute.method_name)
      value = nil if value == attribute.default

      #
      # Apply any on_save lambda/proc or value defined on the attribute.
      #
      value = apply_on_save_action(attribute, value)

      #
      # Attributes that have a nil value should be ignored unless they explicitly
      # state that they should be expressed in the output.
      #
      next if value.nil? && !attribute.options[:state_when_nil]

      attribute_namespace = attribute.options[:namespace]
      attribute_name = if attribute_namespace
                         "#{attribute_namespace}:#{attribute.tag}"
                       else
                         attribute.tag.to_s
                       end
      [attribute_name, value]
    end

    attributes.to_h
  end

  #
  # Add all the registered namespaces to the builder's root element.
  # When this is called recursively by composed classes the namespaces
  # are still added to the root element
  #
  # However, we do not want to add the namespace if the namespace is 'xmlns'
  # which means that it is the default namespace of the code.
  #
  def register_namespaces_with_builder(builder)
    return unless self.class.instance_variable_get(:@registered_namespaces)

    self.class.instance_variable_get(:@registered_namespaces).sort.each do |name, href|
      name = nil if name == "xmlns"
      builder.doc.root.add_namespace(name, href)
    end
  end

  # Persist a single nested element as xml
  def element_to_xml(element, xml, default_namespace)
    #
    # If an element is marked as read only do not consider at all when
    # saving to XML.
    #
    return if element.options[:read_only]

    tag = element.tag || element.name

    #
    # The value to store is the result of the method call to the element,
    # by default this is simply utilizing the attr_accessor defined. However,
    # this allows for this method to be overridden
    #
    value = send(element.name)

    #
    # Apply any on_save action defined on the element.
    #
    value = apply_on_save_action(element, value)

    #
    # To allow for us to treat both groups of items and singular items
    # equally we wrap the value and treat it as an array.
    #
    values = if value.respond_to?(:to_ary) && !element.options[:single]
               value.to_ary
             else
               [value]
             end

    values.each do |item|
      if item.is_a?(HappyMapper)

        #
        # Other items are convertable to xml through the xml builder
        # process should have their contents retrieved and attached
        # to the builder structure
        #
        item.to_xml(xml, self.class.namespace || default_namespace,
                    element.options[:namespace],
                    element.options[:tag] || nil)

      elsif !item.nil? || element.options[:state_when_nil]

        item_namespace =
          element.options[:namespace] ||
          self.class.namespace ||
          default_namespace

        #
        # When a value exists or the tag should always be emitted,
        # we should append the value for the tag
        #
        if item_namespace
          xml.send(:"#{tag}_", item.to_s) do |child_xml|
            child_xml.parent.namespace =
              xml.doc.root.namespace_definitions.find { |x| x.prefix == item_namespace }
          end
        else
          xml.send(:"#{tag}_", item.to_s)
        end
      end
    end
  end

  def wrapper_anonymous_classes
    self.class.instance_variable_get(:@wrapper_anonymous_classes)
  end
end

require "happymapper/supported_types"
require "happymapper/item"
require "happymapper/attribute"
require "happymapper/element"
require "happymapper/text_node"
