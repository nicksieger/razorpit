require 'razorpit/nodes'
require 'razorpit/parser'

module RazorPit

class Context
  module Semantics
    extend self

    Nodes::Number.class_eval do
      def evaluate
        value
      end
    end

    Nodes::Add.class_eval do
      def evaluate
        lhs.evaluate + rhs.evaluate
      end
    end
  end

  def eval(string)
    ast = Parser.parse_expression(string)
    ast.evaluate
  end
end

end
