# frozen_string_literal: true

module HappyMapper
  class Item
    attr_accessor :name, :type, :tag, :options, :namespace

    # options:
    #   :deep   =>  Boolean False to only parse element's children, True to include
    #               grandchildren and all others down the chain (// in xpath)
    #   :namespace => String Element's namespace if it's not the global or inherited
    #                  default
    #   :parser =>  Symbol Class method to use for type coercion.
    #   :raw    =>  Boolean Use raw node value (inc. tags) when parsing.
    #   :single =>  Boolean False if object should be collection, True for single object
    #   :tag    =>  String Element name if it doesn't match the specified name.
    def initialize(name, type, options = {})
      self.name = name.to_s
      self.type = type
      # self.tag = options.delete(:tag) || name.to_s
      self.tag = options[:tag] || name.to_s
      self.namespace = options[:namespace]&.to_s
      self.options = { single: true }.merge(options.merge(name: self.name))

      @xml_type = self.class.to_s.split("::").last.downcase
    end

    def constant
      @constant ||= constantize(type)
    end

    #
    # @param [Nokogiri::XML::Element] node the xml node that is being parsed
    # @param [String] namespace the name of the namespace
    # @param [Hash] xpath_options additional xpath options
    #
    def from_xml_node(node, namespace, xpath_options)
      namespace = self.namespace if options.key?(:namespace)

      if custom_parser_defined?
        find(node, namespace, xpath_options) { |n| process_node_with_custom_parser(n) }
      elsif suported_type_registered?
        find(node, namespace, xpath_options) { |n| process_node_as_supported_type(n) }
      elsif constant == XmlContent
        find(node, namespace, xpath_options) { |n| process_node_as_xml_content(n) }
      else
        process_node_with_default_parser(node, namespaces: xpath_options)
      end
    end

    def xpath(namespace = self.namespace)
      xpath  = ""
      xpath += ".//" if options[:deep]
      xpath += "#{namespace}:" if namespace
      xpath += tag
      # puts "xpath: #{xpath}"
      xpath
    end

    def method_name
      @method_name ||= name.tr("-", "_")
    end

    #
    # Convert the value into the correct type.
    #
    # @param [String] value the string value parsed from the XML value that will
    #     be converted to the particular primitive type.
    #
    # @return [String,Float,Time,Date,DateTime,Boolean,Integer] the converted value
    #     to the new type.
    #
    def typecast(value)
      typecaster(value).apply(value)
    end

    private

    # @return [Boolean] true if the type defined for the item is defined in the
    #     list of support types.
    def suported_type_registered?
      SupportedTypes.types.map(&:type).include?(constant)
    end

    # @return [#apply] the typecaster object that will be able to convert
    #   the value into a value with the correct type.
    def typecaster(value)
      SupportedTypes.types.find { |caster| caster.apply?(value, constant) }
    end

    #
    # Processes a Nokogiri::XML::Node as a supported type
    #
    def process_node_as_supported_type(node)
      content = node.respond_to?(:content) ? node.content : node
      typecast(content)
    end

    #
    # Process a Nokogiri::XML::Node as XML Content
    #
    def process_node_as_xml_content(node)
      node = node.children if node.respond_to?(:children)
      node.respond_to?(:to_xml) ? node.to_xml : node.to_s
    end

    #
    # A custom parser is a custom parse method on the class. When the parser
    # option has been set this value is the name of the method which will be
    # used to parse the node content.
    #
    def custom_parser_defined?
      options[:parser]
    end

    def process_node_with_custom_parser(node)
      value = if node.respond_to?(:content) && !options[:raw]
                node.content
              else
                node.to_s
              end

      custom_parser = create_custom_parser(options[:parser])

      custom_parser.call(value)
    end

    def create_custom_parser(parser)
      return parser if parser.respond_to?(:call)

      proc { |value|
        constant.send(parser.to_sym, value)
      }
    end

    def process_node_with_default_parser(node, parse_options)
      constant.parse(node, options.merge(parse_options))
    end

    #
    # Convert any String defined types into their constant version so that
    # the method #parse or the custom defined parser method would be used.
    #
    # @param [String,Constant] type is the name of the class or the constant
    #     for the class.
    # @return [Constant] the constant of the type
    #
    def constantize(type)
      type.is_a?(String) ? convert_string_to_constant(type) : type
    end

    def convert_string_to_constant(type)
      names = type.split("::")
      constant = Object
      names.each do |name|
        constant =
          if constant.const_defined?(name)
            constant.const_get(name)
          else
            constant.const_missing(name)
          end
      end
      constant
    end
  end
end
