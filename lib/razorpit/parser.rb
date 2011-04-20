require 'razorpit/tokens'
require 'razorpit/lexer'
require 'razorpit/nodes'

module RazorPit

module Parser
  extend self

  module Grammar
    extend self

    TokenType.module_eval do
      attr_accessor :left_binding_power
    end

    Token.module_eval do
      def prefix(tokens)
        raise "Parse error"
      end

      def suffix(tokens, lhs)
        raise "Parse error"
      end
    end

    MAX_BINDING_POWER = 1.0/0.0 # +Infinity
    MIN_BINDING_POWER = -1.0/0.0 # -Infinity

    def define_literal(token_type, ast_class)
      token_type.left_binding_power = MAX_BINDING_POWER
      token_type.token_class_eval do
        eval <<-EOS
          def prefix(tokens)
            #{ast_class}[value]
          end
        EOS
      end
      self
    end

    def define_infix(token_type, ast_class, binding_power)
      token_type.left_binding_power = binding_power
      token_type.token_class_eval do
        eval <<-EOS
          def suffix(tokens, lhs)
            rhs = Grammar.expression(tokens, #{binding_power})
            #{ast_class}[lhs, rhs]
          end
        EOS
      end
    end

    def define_prefix(token_type, ast_class, binding_power)
      token_type.token_class_eval do
        eval <<-EOS
          def prefix(tokens)
            expr = Grammar.expression(tokens, #{binding_power})
            #{ast_class}[expr]
          end
        EOS
      end
    end

    Tokens::OPEN_PAREN.left_binding_power = MIN_BINDING_POWER
    Tokens::OPEN_PAREN.token_class_eval do
      def prefix(tokens)
        expr = Grammar.expression(tokens, MIN_BINDING_POWER)
        raise "syntax error" unless Tokens::CLOSE_PAREN === tokens.next
        expr
      end
    end
    Tokens::CLOSE_PAREN.left_binding_power = MIN_BINDING_POWER

    Tokens::EOF.left_binding_power = MIN_BINDING_POWER
    Tokens::EOF.token_class_eval do
      def suffix(tokens, lhs)
        lhs
      end
    end

    Tokens::NULL.left_binding_power = MAX_BINDING_POWER
    Tokens::NULL.token_class_eval do
      def prefix(tokens)
        Nodes::NULL
      end
    end

    define_literal(Tokens::NUMBER, Nodes::Number)
    define_literal(Tokens::BOOLEAN, Nodes::Boolean)
    define_prefix(Tokens::PLUS, Nodes::UnaryPlus, 100)
    define_prefix(Tokens::MINUS, Nodes::UnaryMinus, 100)
    define_infix(Tokens::PLUS, Nodes::Add, 10)
    define_infix(Tokens::MINUS, Nodes::Subtract, 10)

    # done with these
    undef define_literal
    undef define_prefix
    undef define_infix

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
