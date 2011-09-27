require 'nokogiri'
require 'date'
require 'time'

class Boolean; end
class XmlContent; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.instance_variable_set("@registered_namespaces", {})

    base.extend ClassMethods
  end

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
    def attribute(name, type, options={})
      attribute = Attribute.new(name, type, options)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      attr_accessor attribute.method_name.intern
    end
    
    #
    # The elements defined through {#attribute}.
    # 
    # @return [Array<Attribute>] a list of the attributes defined for this class; 
    #     an empty array is returned when there have been no attributes defined.
    #
    def attributes
      @attributes[to_s] || []
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
    # @param [String] namespace the xml prefix
    # @param [String] ns url for the xml namespace
    #
    def register_namespace(namespace, ns)
      @registered_namespaces.merge!({namespace => ns})
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
    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
    end

    #
    # The elements defined through {#element}, {#has_one}, and {#has_many}.
    # 
    # @return [Array<Element>] a list of the elements contained defined for this
    #     class; an empty array is returned when there have been no elements
    #     defined.
    #
    def elements
      @elements[to_s] || []
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
    #     text_node :first_name, String
    # 
    # @param [Symbol] name the name of the accessor that is created
    # @param [String,Class] type the class name of the name of the class whcih
    #     the object will be converted upon parsing
    # @param [Hash] options additional parameters to send to the relationship
    #
    def text_node(name, type, options={})
      @text_node = TextNode.new(name, type, options)
      attr_accessor @text_node.method_name.intern
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
    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
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
    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
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
      @namespace
    end

    #
    # @param [String] new_tag_name the name for the tag
    #
    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s unless new_tag_name.nil? || new_tag_name.to_s.empty?
    end

    #
    # The name of the tag
    # 
    # @return [String] the name of the tag as a string, downcased
    #
    def tag_name
      @tag_name ||= to_s.split('::')[-1].downcase
    end

    #
    # @param [Nokogiri::XML::Node,Nokogiri:XML::Document,String] xml the XML 
    #     contents to convert into Object.
    # @param [Hash] options additional information for parsing. :single => true
    #     if requesting a single object, otherwise it defaults to retuning an 
    #     array of multiple items. :xpath information where to start the parsing
    #     :namespace is the namespace to use for additional information.
    #
    def parse(xml, options = {})
      
      # create a local copy of the objects namespace value for this parse execution
      namespace = @namespace
      
      # If the XML specified is an Node then we have what we need.
      if xml.is_a?(Nokogiri::XML::Node)
        node = xml
      else
        
        # If xml is an XML document select the root node of the document
        if xml.is_a?(Nokogiri::XML::Document)
          node = xml.root
        else
          
          # Attempt to parse the xml value with Nokogiri XML as a document
          # and select the root element
          
          xml = Nokogiri::XML(xml)
          node = xml.root
        end

        # if the node name is equal to the tag name then the we are parsing the
        # root element and that is important to record so that we can apply
        # the correct xpath on the elements of this document.

        root = node.name == tag_name
      end

      # if any namespaces have been provied then we should capture those and then
      # merge them with any namespaces found on the xml node and merge all that
      # with any namespaces that have been registered on the object
      
      namespaces = options[:namespaces] || {}
      namespaces = namespaces.merge(xml.collect_namespaces) if xml.respond_to?(:collect_namespaces)
      namespaces = namespaces.merge(@registered_namespaces)
      
      # if a namespace has been provided then set the current namespace to it
      # or set the default namespace to the one defined under 'xmlns' 
      # or set the default namespace to the namespace that matches 'happymapper's

      if options[:namespace]
        namespace = options[:namespace]
      elsif namespaces.has_key?("xmlns")
        namespace ||= DEFAULT_NS
        namespaces[namespace] = namespaces.delete("xmlns")
      elsif namespaces.has_key?(DEFAULT_NS)
        namespace ||= DEFAULT_NS
      end
      
      # from the options grab any nodes present and if none are present then
      # perform the following to find the nodes for the given class 
      
      nodes = options.fetch(:nodes) do
        
        # when at the root use the xpath '/' otherwise use a more gready './/'
        # unless an xpath has been specified, which should overwrite default
        # and finally attach the current namespace if one has been defined
        # 
        
        xpath  = (root ? '/' : './/')
        xpath  = options[:xpath].to_s.sub(/([^\/])$/, '\1/') if options[:xpath]
        xpath += "#{namespace}:" if namespace
        #puts "parse: #{xpath}"

        nodes = []

        # when finding nodes, do it in this order:
        # 1. specified tag
        # 2. name of element
        # 3. tag_name (derived from class name by default)
        
        
        [options[:tag], options[:name], tag_name].compact.each do |xpath_ext|
          begin
          nodes = node.xpath(xpath + xpath_ext.to_s, namespaces)
          rescue
            break
          end
          break if nodes && !nodes.empty?
        end

        nodes
      end

      
      collection = nodes.collect do |n|
        obj = new

        attributes.each do |attr|
          obj.send("#{attr.method_name}=",
                    attr.from_xml_node(n, namespace, namespaces))
        end

        elements.each do |elem|
          obj.send("#{elem.method_name}=",
                    elem.from_xml_node(n, namespace, namespaces))
        end

        obj.send("#{@text_node.method_name}=",
                  @text_node.from_xml_node(n, namespace, namespaces)) if @text_node

        if obj.respond_to?('xml_content=')
          n = n.children if n.respond_to?(:children)
          obj.xml_content = n.to_xml
        end

        obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil

      if options[:single] || root
        collection.first
      else
        collection
      end
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
  # @param [String] default_namespace the name of the namespace which is the
  #     default for the xml being produced; this is specified by the element
  #     declaration when calling #to_xml recursively.
  #
  # @return [String,Nokogiri::XML::Builder] return XML representation of the
  #      HappyMapper object; when called recursively this is going to return
  #      and Nokogiri::XML::Builder object.
  #
  def to_xml(builder = nil,default_namespace = nil)
    
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
    
    #
    # Find the attributes for the class and collect them into an array
    # that will be placed into a Hash structure
    #
    attributes = self.class.attributes.collect do |attribute|
      
      #
      # If an attribute is marked as read_only then we want to ignore the attribute
      # when it comes to saving the xml document; so we wiill not go into any of
      # the below process
      # 
      unless attribute.options[:read_only]
      
        value = send(attribute.method_name)
      
        #
        # If the attribute defines an on_save lambda/proc or value that maps to 
        # a method that the class has defined, then call it with the value as a
        # parameter.
        #
        if on_save_action = attribute.options[:on_save]
          if on_save_action.is_a?(Proc)
            value = on_save_action.call(value)
          elsif respond_to?(on_save_action)
            value = send(on_save_action,value)
          end
        end
      
        #
        # Attributes that have a nil value should be ignored unless they explicitly
        # state that they should be expressed in the output.
        #
        if value || attribute.options[:state_when_nil]
          attribute_namespace = attribute.options[:namespace] || default_namespace
          [ "#{attribute_namespace ? "#{attribute_namespace}:" : ""}#{attribute.tag}", value ]
        else
          []
        end
        
      else
        []
      end
      
    end.flatten
    
    attributes = Hash[ *attributes ]

    #
    # Create a tag in the builder that matches the class's tag name and append
    # any attributes to the element that were defined above.
    #
    builder.send(self.class.tag_name,attributes) do |xml|
      
      #
      # Add all the registered namespaces to the root element.
      # When this is called recurisvely by composed classes the namespaces
      # are still added to the root element
      # 
      # However, we do not want to add the namespace if the namespace is 'xmlns'
      # which means that it is the default namesapce of the code.
      #
      if self.class.instance_variable_get('@registered_namespaces') && builder.doc.root
        self.class.instance_variable_get('@registered_namespaces').each_pair do |name,href|
          name = nil if name == "xmlns"
          builder.doc.root.add_namespace(name,href)
        end
      end
      
      #
      # If the object we are persisting has a namespace declaration we will want
      # to use that namespace or we will use the default namespace.
      # When neither are specifed we are simply using whatever is default to the
      # builder
      #
      if self.class.respond_to?(:namespace) && self.class.namespace
        xml.parent.namespace = builder.doc.root.namespace_definitions.find { |x| x.prefix == self.class.namespace }
      elsif default_namespace
        xml.parent.namespace = builder.doc.root.namespace_definitions.find { |x| x.prefix == default_namespace }
      end

      
      #
      # When a text_node has been defined we add the resulting value
      # the output xml
      #
      if text_node = self.class.instance_variable_get('@text_node')
        
        unless text_node.options[:read_only]
          text_accessor = text_node.tag || text_node.name
          value = send(text_accessor)
        
          if on_save_action = text_node.options[:on_save]
            if on_save_action.is_a?(Proc)
              value = on_save_action.call(value)
            elsif respond_to?(on_save_action)
              value = send(on_save_action,value)
            end
          end
        
          builder.text(value)
        end
        
      end

      #
      # for every define element (i.e. has_one, has_many, element) we are
      # going to persist each one
      #
      self.class.elements.each do |element|
        
        #
        # If an element is marked as read only do not consider at all when 
        # saving to XML.
        # 
        unless element.options[:read_only]
          
          tag = element.tag || element.name
          
          #
          # The value to store is the result of the method call to the element,
          # by default this is simply utilizing the attr_accessor defined. However,
          # this allows for this method to be overridden
          #
          value = send(element.name)

          #
          # If the element defines an on_save lambda/proc then we will call that
          # operation on the specified value. This allows for operations to be 
          # performed to convert the value to a specific value to be saved to the xml.
          #
          if on_save_action = element.options[:on_save]
            if on_save_action.is_a?(Proc)
              value = on_save_action.call(value)
            elsif respond_to?(on_save_action)
              value = send(on_save_action,value)
            end 
          end

          #
          # Normally a nil value would be ignored, however if specified then
          # an empty element will be written to the xml
          #
          if value.nil? && element.options[:single] && element.options[:state_when_nil]
            xml.send(tag,"")
          end
        
          #
          # To allow for us to treat both groups of items and singular items
          # equally we wrap the value and treat it as an array.
          #
          if value.nil?
            values = []
          elsif value.respond_to?(:to_ary) && !element.options[:single]
            values = value.to_ary
          else
            values = [value]
          end
        
          values.each do |item|

            if item.is_a?(HappyMapper)

              #
              # Other items are convertable to xml through the xml builder
              # process should have their contents retrieved and attached
              # to the builder structure
              #
              item.to_xml(xml,element.options[:namespace])

            elsif item
            
              item_namespace = element.options[:namespace] || default_namespace
            
              #
              # When a value exists we should append the value for the tag
              #
              if item_namespace
                xml[item_namespace].send(tag,item.to_s)
              else
                xml.send(tag,item.to_s)
              end

            else

              #
              # Normally a nil value would be ignored, however if specified then
              # an empty element will be written to the xml
              #
              xml.send(tag,"") if element.options[:state_when_nil]

            end

          end
          
        end
      end

    end

    write_out_to_xml ? builder.to_xml : builder
    
  end
  
  
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
require 'happymapper/text_node'
