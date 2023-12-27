# frozen_string_literal: true

require "happymapper/syntax_error"

module HappyMapper
  # Class methods to be applied to classes that include the HappyMapper module.
  module ClassMethods
    #
    # The xml has the following attributes defined.
    #
    # @example
    #
    #     "<country code='de'>Germany</country>"
    #
    #     # definition of the 'code' attribute within the class
    #     attribute :code, String
    #
    # @param [Symbol] name the name of the accessor that is created
    # @param [String,Class] type the class name of the name of the class whcih
    #     the object will be converted upon parsing
    # @param [Hash] options additional parameters to send to the relationship
    #
    def attribute(name, type, options = {})
      attribute = Attribute.new(name, type, options)
      @attributes[name] = attribute
      attr_accessor attribute.method_name.intern
    end

    #
    # The elements defined through {#attribute}.
    #
    # @return [Array<Attribute>] a list of the attributes defined for this class;
    #     an empty array is returned when there have been no attributes defined.
    #
    def attributes
      @attributes.values
    end

    #
    # Register a namespace that is used to persist the object namespace back to
    # XML.
    #
    # @example
    #
    #     register_namespace 'prefix', 'http://www.unicornland.com/prefix'
    #
    #     # the output will contain the namespace defined
    #
    #     "<outputXML xmlns:prefix="http://www.unicornland.com/prefix">
    #     ...
    #     </outputXML>"
    #
    # @param [String] name the xml prefix
    # @param [String] href url for the xml namespace
    #
    def register_namespace(name, href)
      @registered_namespaces.merge!(name => href)
    end

    #
    # An element defined in the XML that is parsed.
    #
    # @example
    #
    #     "<address location='home'>
    #        <city>Oldenburg</city>
    #      </address>"
    #
    #     # definition of the 'city' element within the class
    #
    #     element :city, String
    #
    # @param [Symbol] name the name of the accessor that is created
    # @param [String,Class] type the class name of the name of the class whcih
    #     the object will be converted upon parsing
    # @param [Hash] options additional parameters to send to the relationship
    #
    def element(name, type, options = {})
      element = Element.new(name, type, options)
      attr_accessor element.method_name.intern unless @elements[name]
      @elements[name] = element
    end

    #
    # The elements defined through {#element}, {#has_one}, and {#has_many}.
    #
    # @return [Array<Element>] a list of the elements contained defined for this
    #     class; an empty array is returned when there have been no elements
    #     defined.
    #
    def elements
      @elements.values
    end

    #
    # The value stored in the text node of the current element.
    #
    # @example
    #
    #     "<firstName>Michael Jackson</firstName>"
    #
    #     # definition of the 'firstName' text node within the class
    #
    #     content :first_name, String
    #
    # @param [Symbol] name the name of the accessor that is created
    # @param [String,Class] type the class name of the name of the class whcih
    #     the object will be converted upon parsing. By Default String class will be taken.
    # @param [Hash] options additional parameters to send to the relationship
    #
    def content(name, type = String, options = {})
      @content = TextNode.new(name, type, options)
      attr_accessor @content.method_name.intern
    end

    #
    # Sets the object to have xml content, this will assign the XML contents
    # that are parsed to the attribute accessor xml_content. The object will
    # respond to the method #xml_content and will return the XML data that
    # it has parsed.
    #
    def has_xml_content
      attr_accessor :xml_content
    end

    #
    # The object has one of these elements in the XML. If there are multiple,
    # the last one will be set to this value.
    #
    # @param [Symbol] name the name of the accessor that is created
    # @param [String,Class] type the class name of the name of the class whcih
    #     the object will be converted upon parsing
    # @param [Hash] options additional parameters to send to the relationship
    #
    # @see #element
    #
    def has_one(name, type, options = {})
      element name, type, { single: true }.merge(options)
    end

    #
    # The object has many of these elements in the XML.
    #
    # @param [Symbol] name the name of accessor that is created
    # @param [String,Class] type the class name or the name of the class which
    #     the object will be converted upon parsing.
    # @param [Hash] options additional parameters to send to the relationship
    #
    # @see #element
    #
    def has_many(name, type, options = {})
      element name, type, { single: false }.merge(options)
    end

    #
    # The list of registered after_parse callbacks.
    #
    def after_parse_callbacks
      @after_parse_callbacks ||= []
    end

    #
    # Register a new after_parse callback, given as a block.
    #
    # @yield [object] Yields the newly-parsed object to the block after parsing.
    #     Sub-objects will be already populated.
    def after_parse(&block)
      after_parse_callbacks.push(block)
    end

    #
    # Specify a namespace if a node and all its children are all namespaced
    # elements. This is simpler than passing the :namespace option to each
    # defined element.
    #
    # @param [String] namespace the namespace to set as default for the class
    #     element.
    #
    def namespace(namespace = nil)
      @namespace = namespace if namespace
      @namespace if defined? @namespace
    end

    #
    # @param [String] new_tag_name the name for the tag
    #
    def tag(new_tag_name)
      return if new_tag_name.nil? || (name = new_tag_name.to_s).empty?

      raise SyntaxError, "Unexpected ':' in tag name #{new_tag_name}" if name.include? ":"

      @tag_name = name
    end

    #
    # The name of the tag
    #
    # @return [String] the name of the tag as a string, downcased
    #
    def tag_name
      @tag_name ||= name && name.to_s.split("::")[-1].downcase
    end

    # There is an XML tag that needs to be known for parsing and should be generated
    # during a to_xml.  But it doesn't need to be a class and the contained elements should
    # be made available on the parent class
    #
    # @param [String] name the name of the element that is just a place holder
    # @param [Proc] blk the element definitions inside the place holder tag
    #
    def wrap(name, options = {}, &blk)
      # Get an anonymous HappyMapper that has 'name' as its tag and defined
      # in '&blk'.  Then save that to a class instance variable for later use
      wrapper = AnonymousWrapperClassFactory.get(name, &blk)
      wrapper_key = wrapper.inspect
      @wrapper_anonymous_classes[wrapper_key] = wrapper

      # Create getter/setter for each element and attribute defined on the
      # anonymous HappyMapper onto this class. They get/set the value by
      # passing thru to the anonymous class.
      passthrus = wrapper.attributes + wrapper.elements
      passthrus.each do |item|
        method_name = item.method_name
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method_name}                                    # def property
            @#{name} ||=                                        #   @wrapper ||=
              wrapper_anonymous_classes['#{wrapper_key}'].new   #     wrapper_anonymous_classes['#<Class:0x0000555b7d0b9220>'].new
            @#{name}.#{method_name}                             #   @wrapper.property
          end                                                   # end

          def #{method_name}=(value)                            # def property=(value)
            @#{name} ||=                                        #   @wrapper ||=
              wrapper_anonymous_classes['#{wrapper_key}'].new   #     wrapper_anonymous_classes['#<Class:0x0000555b7d0b9220>'].new
            @#{name}.#{method_name} = value                     #   @wrapper.property = value
          end                                                   # end
        RUBY
      end

      has_one name, wrapper, options
    end

    # The callback defined through {.with_nokogiri_config}.
    #
    # @return [Proc] the proc to pass to Nokogiri to setup parse options. nil if empty.
    #
    attr_reader :nokogiri_config_callback

    # Register a config callback according to the block Nokogori expects when
    # calling Nokogiri::XML::Document.parse().
    #
    # See http://nokogiri.org/Nokogiri/XML/Document.html#method-c-parse
    #
    # @param [Proc] the proc to pass to Nokogiri to setup parse options
    #
    def with_nokogiri_config(&blk)
      @nokogiri_config_callback = blk
    end

    #
    # @param [Nokogiri::XML::Node,Nokogiri:XML::Document,String] xml the XML
    #     contents to convert into Object.
    # @param [Hash] options additional information for parsing.
    #     :single => true if requesting a single object, otherwise it defaults
    #     to retuning an array of multiple items.
    #     :xpath information where to start the parsing
    #     :namespace is the namespace to use for additional information.
    #
    def parse(xml, options = {})
      # Capture any provided namespaces and merge in any namespaces that have
      # been registered on the object.
      namespaces = options[:namespaces] || {}
      namespaces = namespaces.merge(@registered_namespaces)

      # If the XML specified is an Node then we have what we need.
      if xml.is_a?(Nokogiri::XML::Node) && !xml.is_a?(Nokogiri::XML::Document)
        node = xml
      else

        unless xml.is_a?(Nokogiri::XML::Document)
          # Attempt to parse the xml value with Nokogiri XML as a document
          # and select the root element
          xml = Nokogiri::XML(
            xml, nil, nil,
            Nokogiri::XML::ParseOptions::STRICT,
            &nokogiri_config_callback
          )
        end
        # Now xml is certainly an XML document: Select the root node of the document
        node = xml.root

        # merge any namespaces found on the xml node into the namespace hash
        namespaces = namespaces.merge(xml.collect_namespaces)

        # if the node name is equal to the tag name then the we are parsing the
        # root element and that is important to record so that we can apply
        # the correct xpath on the elements of this document.

        root = node.name == tag_name
      end

      # If the :single option has been specified or we are at the root element
      # then we are going to return a single element or nil if no nodes are found
      single = root || options[:single]

      # if a namespace has been provided then set the current namespace to it
      # or use the namespace provided by the class
      # or use the 'xmlns' namespace if defined

      namespace =
        options[:namespace] ||
        self.namespace ||
        namespaces.key?("xmlns") && "xmlns"

      # from the options grab any nodes present and if none are present then
      # perform the following to find the nodes for the given class

      nodes = options.fetch(:nodes) do
        find_nodes_to_parse(options, namespace, tag_name, namespaces, node, root)
      end

      # Nothing matching found, we can go ahead and return
      return (single ? nil : []) if nodes.empty?

      # If the :limit option has been specified then we are going to slice
      # our node results by that amount to allow us the ability to deal with
      # a large result set of data.

      limit = options[:in_groups_of] || nodes.size

      # If the limit of 0 has been specified then the user obviously wants
      # none of the nodes that we are serving within this batch of nodes.

      return [] if limit == 0

      collection = []

      nodes.each_slice(limit) do |slice|
        part = slice.map do |n|
          parse_node(n, options, namespace, namespaces)
        end

        # If a block has been provided and the user has requested that the objects
        # be handled in groups then we should yield the slice of the objects to them
        # otherwise continue to lump them together

        if block_given? && options[:in_groups_of]
          yield part
        else
          collection += part
        end
      end

      # If we're parsing a single element then we are going to return the first
      # item in the collection. Otherwise the return response is going to be an
      # entire array of items.

      if single
        collection.first
      else
        collection
      end
    end

    # @private
    def defined_content
      @content if defined? @content
    end

    private

    def find_nodes_to_parse(options, namespace, tag_name, namespaces, node, root)
      # when at the root use the xpath '/' otherwise use a more gready './/'
      # unless an xpath has been specified, which should overwrite default
      # and finally attach the current namespace if one has been defined
      #

      xpath = if options[:xpath]
                options[:xpath].to_s.sub(%r{([^/])$}, '\1/')
              elsif root
                "/"
              else
                ".//"
              end
      if namespace
        unless namespaces.find { |name, _| ["xmlns:#{namespace}", namespace].include? name }
          return []
        end

        xpath += "#{namespace}:"
      end

      nodes = []

      # when finding nodes, do it in this order:
      # 1. specified tag if one has been provided
      # 2. name of element
      # 3. tag_name (derived from class name by default)

      # If a tag has been provided we need to search for it.

      if options.key?(:tag)
        nodes = node.xpath(xpath + options[:tag].to_s, namespaces)
      else

        # This is the default case when no tag value is provided.
        # First we use the name of the element `items` in `has_many items`
        # Second we use the tag name which is the name of the class cleaned up

        [options[:name], tag_name].compact.each do |xpath_ext|
          nodes = node.xpath(xpath + xpath_ext.to_s, namespaces)
          break if nodes && !nodes.empty?
        end

      end

      nodes
    end

    def parse_node(node, options, namespace, namespaces)
      # If an existing HappyMapper object is provided, update it with the
      # values from the xml being parsed.  Otherwise, create a new object

      obj = options[:update] || new

      attributes.each do |attr|
        value = attr.from_xml_node(node, namespace, namespaces)
        value = attr.default if value.nil?
        obj.send(:"#{attr.method_name}=", value)
      end

      elements.each do |elem|
        obj.send(:"#{elem.method_name}=", elem.from_xml_node(node, namespace, namespaces))
      end

      if (content = defined_content)
        obj.send(:"#{content.method_name}=",
                 content.from_xml_node(node, namespace, namespaces))
      end

      # If the HappyMapper class has the method #xml_value=,
      # attr_writer :xml_value, or attr_accessor :xml_value then we want to
      # assign the current xml that we just parsed to the xml_value

      if obj.respond_to?(:xml_value=)
        obj.xml_value = node.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      # If the HappyMapper class has the method #xml_content=,
      # attr_write :xml_content, or attr_accessor :xml_content then we want to
      # assign the child xml that we just parsed to the xml_content

      if obj.respond_to?(:xml_content=)
        node = node.children if node.respond_to?(:children)
        obj.xml_content = node.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      # Call any registered after_parse callbacks for the object's class

      obj.class.after_parse_callbacks.each { |callback| callback.call(obj) }

      # collect the object that we have created

      obj
    end
  end
end
