require 'razorpit/nodes'

module RazorPit

module Eval
  module Semantics
    LiteralNode.class_eval do
      def evaluate
        value
      end
    end

    Nodes::UnaryPlus.class_eval do
      def evaluate
        expr.evaluate
      end
    end

    Nodes::Add.class_eval do
      def evaluate
        lhs.evaluate + rhs.evaluate
      end
    end

    Nodes::Subtract.class_eval do
      def evaluate
        lhs.evaluate - rhs.evaluate
      end
    end

    class << Nodes::NULL
      def evaluate
        nil
      end
    end
  end
end

end
