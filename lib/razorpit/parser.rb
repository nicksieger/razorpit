require 'razorpit/lexer'
require 'razorpit/nodes'

module RazorPit

module Parser
  extend self

  module Grammar
    extend self

    MAX_BINDING_POWER = 1.0/0.0 # +Infinity
    MIN_BINDING_POWER = -1.0/0.0 # -Infinity

    Tokens::NUMBER.token_class_eval do
      def left_binding_power; MAX_BINDING_POWER; end
      def prefix(tokens)
        Nodes::Number[value]
      end
    end

    Tokens::PLUS.token_class_eval do
      def left_binding_power; 10; end
      def suffix(tokens, lhs)
        rhs = Grammar.expression(tokens, left_binding_power)
        Nodes::Add[lhs, rhs]
      end
    end

    Tokens::EOF.token_class_eval do
      def left_binding_power; MIN_BINDING_POWER; end
      def suffix(tokens, lhs)
        lhs
      end
    end

    def expression(tokens, right_binding_power)
      token = tokens.next
      ast = token.prefix(tokens)
      while tokens.peek.left_binding_power > right_binding_power
        token = tokens.next
        ast = token.suffix(tokens, ast)
      end
      ast
    end
  end

  def parse(string)
    Nodes::Program[]
  end

  def parse_expression(string)
    tokens = Lexer.scan(string)
    Grammar.expression(tokens, Grammar::MIN_BINDING_POWER)
  end
end

end
