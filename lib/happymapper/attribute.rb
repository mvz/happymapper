module HappyMapper
  class Attribute < Item
    attr_accessor :default

    # @see Item#initialize
    # Additional options:
    #   :default => Object The default value for this
    def initialize(name, type, o={})
      super
      self.default = o[:default]
    end
  end
end