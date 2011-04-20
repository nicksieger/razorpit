require 'razorpit/nodes'

module RazorPit

module Eval
  module Semantics
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
end

end
