module HappyMapper
  module SupportedTypes
    extend self

    #
    # All of the registerd supported types that can be parsed.
    #
    # All types defined here are set through #register.
    #
    def types
      @types ||= []
    end

    #
    # Add a new converter to the list of supported types. A converter
    # is an object that adheres to the protocol which is defined with two
    # methods #apply?(value,convert_to_type) and #apply(value).
    #
    # @example Defining a class that would process `nil` or values that have
    #   already been converted.
    #
    #     class NilOrAlreadyConverted
    #       def apply?(value,convert_to_type)
    #         value.kind_of?(convert_to_type) || value.nil?
    #       end
    #
    #       def apply(value)
    #         value
    #       end
    #     end
    #
    #
    def register(type_converter)
      types.push type_converter
    end

    #
    # An additional shortcut registration method that assumes that you want
    # to perform a conversion on a specific type. A block is provided which
    # is the operation to perform when #apply(value) has been called.
    #
    # @example Registering a DateTime parser
    #
    #     HappyMapper::SupportedTypes.register_type DateTime do |value|
    #       DateTime.parse(value,to_s)
    #     end
    #
    def register_type(type,&block)
      register CastWhenType.new(type,&block)
    end

    #
    # Many of the conversions are based on type. When the type specified
    # matches then perform the action specified in the specified block.
    # If no block is provided the value is simply returned.
    #
    class CastWhenType
      attr_reader :type

      def initialize(type,&block)
        @type = type
        @apply_block = block || no_operation
      end

      def no_operation
        lambda {|value| value }
      end

      def apply?(value,convert_to_type)
        convert_to_type == type
      end

      def apply(value)
        @apply_block.call(value)
      end
    end

    #
    # For the cases when the value is nil or is already the
    # intended type then no work needs to be done and the
    # value simply can be returned.
    #
    class NilOrAlreadyConverted

      def type
        NilClass
      end

      def apply?(value,convert_to_type)
        value.kind_of?(convert_to_type) || value.nil?
      end

      def apply(value)
        value
      end
    end

    register NilOrAlreadyConverted.new

    register_type String do |value|
      value.to_s
    end

    register_type Float do |value|
      value.to_f
    end

    register_type Time do |value|
      Time.parse(value.to_s) rescue Time.at(value.to_i)
    end

    register_type Date do |value|
      Date.parse(value.to_s)
    end

    register_type DateTime do |value|
      DateTime.parse(value.to_s)
    end

    register_type Boolean do |value|
      ['true', 't', '1', 'yes', 'y'].include?(value.to_s.downcase)
    end

    register_type Integer do |value|
      value_to_i = value.to_i
      if value_to_i == 0 && value != '0'
        value_to_s = value.to_s
        begin
          Integer(value_to_s =~ /^(\d+)/ ? $1 : value_to_s)
        rescue ArgumentError
          nil
        end
      else
        value_to_i
      end
    end

  end

end