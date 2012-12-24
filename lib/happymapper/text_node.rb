module HappyMapper
  class TextNode < Item

    def find(node, namespace, xpath_options)
      yield(node.children.detect{|c| c.text?})
    end
  end
end
