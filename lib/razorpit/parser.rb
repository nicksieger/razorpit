require 'razorpit/lexer'
require 'razorpit/nodes'

module RazorPit

module Parser
  extend self

  module Grammar
    extend self

    Tokens::NUMBER.token_class_eval do
      def left_binding_power; 0; end
      def prefix(tokens)
        Nodes::Number[value]
      end
    end

    Tokens::PLUS.token_class_eval do
      def left_binding_power; 10; end
      def infix(tokens, lhs)
        rhs = Grammar.expression(tokens, left_binding_power)
        Nodes::Add[lhs, rhs]
      end
    end

    def expression(tokens, right_binding_power)
      token = tokens.next
      ast = token.prefix(tokens)
      while token.left_binding_power > right_binding_power
        token = tokens.next
        ast = token.infix(tokens, ast)
      end
      ast
    end
  end

  def parse(string)
    Nodes::Program[]
  end

  def parse_expression(string)
    tokens = Lexer.scan(string)
    Grammar.expression(tokens, 0)
  end
end

end
