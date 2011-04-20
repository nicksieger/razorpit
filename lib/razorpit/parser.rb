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
        const_set :LITERAL_AST_CLASS, ast_class
        def prefix(tokens)
          LITERAL_AST_CLASS[value]
        end
      end
      self
    end

    def define_infix(token_type, ast_class, binding_power)
      token_type.left_binding_power = binding_power
      token_type.token_class_eval do
        const_set :INFIX_AST_CLASS, ast_class
        def suffix(tokens, lhs)
          rhs = Grammar.expression(tokens, left_binding_power)
          INFIX_AST_CLASS[lhs, rhs]
        end
      end
    end

    def define_prefix(token_type, ast_class, binding_power)
      token_type.token_class_eval do
        const_set :PREFIX_AST_CLASS, ast_class
        const_set :PREFIX_BINDING_POWER, binding_power
        def prefix(tokens)
          expr = Grammar.expression(tokens, PREFIX_BINDING_POWER)
          PREFIX_AST_CLASS[expr]
        end
      end
    end

    Tokens::EOF.left_binding_power = MIN_BINDING_POWER
    Tokens::EOF.token_class_eval do
      def suffix(tokens, lhs)
        lhs
      end
    end

    define_literal(Tokens::NUMBER, Nodes::Number)
    define_prefix(Tokens::PLUS, Nodes::UnaryPlus, 100)
    define_infix(Tokens::PLUS, Nodes::Add, 10)

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
