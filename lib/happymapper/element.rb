# frozen_string_literal: true

module HappyMapper
  class Element < Item
    def find(node, namespace, xpath_options)
      namespace = self.namespace if self.namespace

      if options[:single]
        result = if options[:xpath]
                   node.xpath(options[:xpath], xpath_options)
                 else
                   node.xpath(xpath(namespace), xpath_options)
                 end

        if result
          value = yield(result.first)
          handle_attributes_option(result, value, xpath_options)
          value
        end
      else
        target_path = options[:xpath] || xpath(namespace)
        node.xpath(target_path, xpath_options).collect do |item|
          value = yield(item)
          handle_attributes_option(item, value, xpath_options)
          value
        end
      end
    end

    def handle_attributes_option(result, value, xpath_options)
      return unless options[:attributes].is_a?(Hash)

      result = result.first unless result.respond_to?(:attribute_nodes)
      return unless result.respond_to?(:attribute_nodes)

      result.attribute_nodes.each do |xml_attribute|
        next unless (attribute_options = options[:attributes][xml_attribute.name.to_sym])

        attribute_value = Attribute.new(xml_attribute.name.to_sym, *attribute_options)
                                   .from_xml_node(result, namespace, xpath_options)

        method_name = xml_attribute.name.tr("-", "_")
        value.define_singleton_method(method_name) { attribute_value }
      end
    end
  end
end
