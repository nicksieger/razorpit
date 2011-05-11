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
        raise "Parse error (#{self} not expected as prefix)"
      end

      def suffix(tokens, lhs)
        raise "Parse error (#{self} not expected as suffix)"
      end

      def left_binding_power
        token_type.left_binding_power
      end
    end

    %w(MIN COMMA ASSIGN CONDITION OR AND
       BITWISE_OR BITWISE_XOR BITWISE_AND
       EQUALITY RELATIONAL SHIFT
       ADD MULT UNARY
       INCREMENT CALL MEMBER MAX).each_with_index do |name, i|
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

    Tokens::PERIOD.left_binding_power = MEMBER_BINDING_POWER
    Tokens::PERIOD.token_class_eval do
      def suffix(tokens, lhs)
        name = Grammar.consume_token(tokens, Tokens::IDENTIFIER)
        Nodes::PropertyAccess[lhs, Nodes::String[name.value]]
      end
    end

    Tokens::OPEN_BRACKET.left_binding_power = MEMBER_BINDING_POWER
    Tokens::OPEN_BRACKET.token_class_eval do
      def suffix(tokens, lhs)
        rhs = Grammar.expression(tokens, MEMBER_BINDING_POWER)
        Grammar.consume_token(tokens, Tokens::CLOSE_BRACKET)
        Nodes::PropertyAccess[lhs, rhs]
      end
    end

    Tokens::INCREMENT.left_binding_power = INCREMENT_BINDING_POWER
    Tokens::INCREMENT.token_class_eval do
      def prefix(tokens)
        expr = Grammar.expression(tokens, INCREMENT_BINDING_POWER)
        Nodes::PreIncrement[expr]
      end

      def suffix(tokens, lhs)
        Nodes::PostIncrement[lhs]
      end
    end

    Tokens::DECREMENT.left_binding_power = INCREMENT_BINDING_POWER
    Tokens::DECREMENT.token_class_eval do
      def prefix(tokens)
        expr = Grammar.expression(tokens, INCREMENT_BINDING_POWER)
        Nodes::PreDecrement[expr]
      end

      def suffix(tokens, lhs)
        Nodes::PostDecrement[lhs]
      end
    end

    Tokens::OPEN_PAREN.left_binding_power = CALL_BINDING_POWER
    Tokens::OPEN_PAREN.token_class_eval do
      def prefix(tokens)
        expr = Grammar.expression(tokens, MIN_BINDING_POWER)
        Grammar.consume_token(tokens, Tokens::CLOSE_PAREN)
        expr
      end

      def suffix(tokens, lhs)
        args = []
        unless Grammar.try_consume_token(tokens, Tokens::CLOSE_PAREN)
          args << Grammar.expression(tokens, COMMA_BINDING_POWER)
          while Grammar.try_consume_token(tokens, Tokens::COMMA)
            args << Grammar.expression(tokens, COMMA_BINDING_POWER)
          end
          Grammar.consume_token(tokens, Tokens::CLOSE_PAREN)
        end
        N::FunctionCall[lhs, *args]
      end
    end

    Tokens::QUESTION.left_binding_power = CONDITION_BINDING_POWER
    Tokens::QUESTION.token_class_eval do
      def suffix(tokens, lhs)
        this_expr = Grammar.expression(tokens, COMMA_BINDING_POWER)
        Grammar.consume_token(tokens, Tokens::COLON)
        else_expr = Grammar.expression(tokens, COMMA_BINDING_POWER)
        Nodes::Condition[lhs, this_expr, else_expr]
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
    define_literal(Tokens::STRING, Nodes::String)
    define_literal(Tokens::REGEX, Nodes::RegEx)
    define_literal(Tokens::IDENTIFIER, Nodes::Identifier)

    define_prefix(Tokens::DELETE, Nodes::Delete, UNARY_BINDING_POWER)
    define_prefix(Tokens::PLUS, Nodes::UnaryPlus, UNARY_BINDING_POWER)
    define_prefix(Tokens::MINUS, Nodes::UnaryMinus, UNARY_BINDING_POWER)
    define_prefix(Tokens::TYPEOF, Nodes::TypeOf, UNARY_BINDING_POWER)
    define_prefix(Tokens::VOID, Nodes::Void, UNARY_BINDING_POWER)
    define_prefix(Tokens::NOT, Nodes::Not, UNARY_BINDING_POWER)
    define_prefix(Tokens::BITWISE_NOT, Nodes::BitwiseNot,
                  UNARY_BINDING_POWER)

    define_infix(Tokens::TIMES, Nodes::Multiply, MULT_BINDING_POWER)
    define_infix(Tokens::DIV, Nodes::Divide, MULT_BINDING_POWER)
    define_infix(Tokens::MODULUS, Nodes::Modulus, MULT_BINDING_POWER)
    define_infix(Tokens::PLUS, Nodes::Add, ADD_BINDING_POWER)
    define_infix(Tokens::MINUS, Nodes::Subtract, ADD_BINDING_POWER)
    define_infix(Tokens::AND, Nodes::And, AND_BINDING_POWER)
    define_infix(Tokens::OR, Nodes::Or, OR_BINDING_POWER)
    define_infix(Tokens::BITWISE_AND, Nodes::BitwiseAnd,
                 BITWISE_AND_BINDING_POWER)
    define_infix(Tokens::BITWISE_OR, Nodes::BitwiseOr,
                 BITWISE_OR_BINDING_POWER)
    define_infix(Tokens::BITWISE_XOR, Nodes::BitwiseXOr,
                 BITWISE_XOR_BINDING_POWER)
    define_infix(Tokens::GT, Nodes::GreaterThan, RELATIONAL_BINDING_POWER)
    define_infix(Tokens::LT, Nodes::LessThan, RELATIONAL_BINDING_POWER)
    define_infix(Tokens::GTE, Nodes::GreaterThanOrEqual, RELATIONAL_BINDING_POWER)
    define_infix(Tokens::LTE, Nodes::LessThanOrEqual, RELATIONAL_BINDING_POWER)
    define_infix(Tokens::EQUAL, Nodes::Equal, EQUALITY_BINDING_POWER)
    define_infix(Tokens::NOT_EQUAL, Nodes::NotEqual, EQUALITY_BINDING_POWER)
    define_infix(Tokens::STRICT_EQUAL, Nodes::StrictlyEqual,
                 EQUALITY_BINDING_POWER)
    define_infix(Tokens::STRICT_NOT_EQUAL, Nodes::StrictlyNotEqual,
                 EQUALITY_BINDING_POWER)
    define_infix(Tokens::SHIFT_LEFT, Nodes::LeftShift, SHIFT_BINDING_POWER)
    define_infix(Tokens::SHIFT_RIGHT_EXTEND, Nodes::SignedRightShift,
                 SHIFT_BINDING_POWER)
    define_infix(Tokens::SHIFT_RIGHT, Nodes::UnsignedRightShift,
                 SHIFT_BINDING_POWER)

    define_infix(Tokens::ASSIGN, Nodes::Assign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::PLUS_ASSIGN, Nodes::AddAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::MINUS_ASSIGN, Nodes::SubtractAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::TIMES_ASSIGN, Nodes::MultiplyAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::DIV_ASSIGN, Nodes::DivideAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::MODULUS_ASSIGN, Nodes::ModulusAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::BITWISE_AND_ASSIGN, Nodes::BitwiseAndAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::BITWISE_OR_ASSIGN, Nodes::BitwiseOrAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::BITWISE_XOR_ASSIGN, Nodes::BitwiseXOrAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::SHIFT_LEFT_ASSIGN, Nodes::LeftShiftAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::SHIFT_RIGHT_EXTEND_ASSIGN, Nodes::SignedRightShiftAssign, ASSIGN_BINDING_POWER)
    define_infix(Tokens::SHIFT_RIGHT_ASSIGN, Nodes::UnsignedRightShiftAssign, ASSIGN_BINDING_POWER)

    define_infix(Tokens::COMMA, Nodes::Sequence, COMMA_BINDING_POWER)

    # done with these
    undef define_literal
    undef define_prefix
    undef define_infix

    def left_binding_power(token)
      token.left_binding_power || MIN_BINDING_POWER
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

    def consume_token(tokens, kind)
      token = tokens.next
      unless kind === token
        raise "Parse error (expected #{kind} but got #{token})"
      end
      token
    end

    def try_consume_token(tokens, kind)
      if kind === tokens.peek
        tokens.next
      else
        nil
      end
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
