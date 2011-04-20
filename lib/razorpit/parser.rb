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

    %w(MIN ADD MULT UNARY MAX).each_with_index do |name, i|
      # use intervals of two to allow for right associativity adjustment
      const_set("#{name}_BINDING_POWER", i * 2)
    end

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

    Tokens::OPEN_PAREN.token_class_eval do
      def prefix(tokens)
        expr = Grammar.expression(tokens, MIN_BINDING_POWER)
        raise "syntax error" unless Tokens::CLOSE_PAREN === tokens.next
        expr
      end
    end

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
    define_prefix(Tokens::PLUS, Nodes::UnaryPlus, UNARY_BINDING_POWER)
    define_prefix(Tokens::MINUS, Nodes::UnaryMinus, UNARY_BINDING_POWER)
    define_infix(Tokens::TIMES, Nodes::Multiply, MULT_BINDING_POWER)
    define_infix(Tokens::DIV, Nodes::Divide, MULT_BINDING_POWER)
    define_infix(Tokens::PLUS, Nodes::Add, ADD_BINDING_POWER)
    define_infix(Tokens::MINUS, Nodes::Subtract, ADD_BINDING_POWER)

    # done with these
    undef define_literal
    undef define_prefix
    undef define_infix

    def left_binding_power(token)
      token.token_type.left_binding_power || MIN_BINDING_POWER
    end

    def expression(tokens, right_binding_power)
      token = tokens.next
      ast = token.prefix(tokens)
      while left_binding_power(tokens.peek) > right_binding_power
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
