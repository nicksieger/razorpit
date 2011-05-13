require 'razorpit/tokens'
require 'razorpit/lexer'
require 'razorpit/nodes'

module RazorPit

class ParseError < RuntimeError
end

class Parser
  module Grammar
    extend self

    TokenType.module_eval do
      attr_accessor :left_binding_power
    end

    Token.module_eval do
      def left_binding_power
        token_type.left_binding_power
      end
    end

    module PrefixToken
    end

    module SuffixToken
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
        include PrefixToken
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
        include SuffixToken
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
        include PrefixToken
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
      include SuffixToken
      def suffix(tokens, lhs)
        name = Grammar.consume_token(tokens, Tokens::IDENTIFIER)
        Nodes::PropertyAccess[lhs, Nodes::String[name.value]]
      end
    end

    Tokens::OPEN_BRACKET.left_binding_power = MEMBER_BINDING_POWER
    Tokens::OPEN_BRACKET.token_class_eval do
      include SuffixToken
      def suffix(tokens, lhs)
        rhs = Grammar.expression(tokens, MEMBER_BINDING_POWER)
        Grammar.consume_token(tokens, Tokens::CLOSE_BRACKET)
        Nodes::PropertyAccess[lhs, rhs]
      end
    end

    Tokens::INCREMENT.left_binding_power = INCREMENT_BINDING_POWER
    Tokens::INCREMENT.token_class_eval do
      include PrefixToken 
      include SuffixToken

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
      include PrefixToken 
      include SuffixToken

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
      include PrefixToken 
      include SuffixToken

      def prefix(tokens)
        expr = Grammar.expression(tokens, MIN_BINDING_POWER)
        Grammar.consume_token(tokens, Tokens::CLOSE_PAREN)
        expr
      end

      def suffix(tokens, lhs)
        args = []
        unless Grammar.try_consume_token(tokens, Tokens::CLOSE_PAREN)
          begin
            args << Grammar.expression(tokens, COMMA_BINDING_POWER)
          end while Grammar.try_consume_token(tokens, Tokens::COMMA)
          Grammar.consume_token(tokens, Tokens::CLOSE_PAREN)
        end
        N::FunctionCall[lhs, *args]
      end
    end

    Tokens::QUESTION.left_binding_power = CONDITION_BINDING_POWER
    Tokens::QUESTION.token_class_eval do
      include SuffixToken
      def suffix(tokens, lhs)
        this_expr = Grammar.expression(tokens, COMMA_BINDING_POWER)
        Grammar.consume_token(tokens, Tokens::COLON)
        else_expr = Grammar.expression(tokens, COMMA_BINDING_POWER)
        Nodes::Condition[lhs, this_expr, else_expr]
      end
    end

    Tokens::NULL.left_binding_power = MAX_BINDING_POWER
    Tokens::NULL.token_class_eval do
      include PrefixToken
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
      token = consume_token(tokens, PrefixToken)
      ast = token.prefix(tokens)
      loop do
        token = try_consume_token(tokens, Proc.new { |t|
          SuffixToken === t and
          left_binding_power(t) > right_binding_power
        })
        break unless token
        ast = token.suffix(tokens, ast)
      end
      ast
    end

    def empty_statement(tokens)
      return nil unless try_consume_token(tokens, Tokens::SEMICOLON)
      Nodes::EmptyStatement[]
    end

    def expression_statement(tokens)
      ast = expression(tokens, MIN_BINDING_POWER)
      consume_token(tokens, Tokens::SEMICOLON)
      ast
    end

    def block_statement(tokens)
      return nil unless try_consume_token(tokens, Tokens::OPEN_BRACE)
      statement_list(tokens, Tokens::CLOSE_BRACE) { |s| Nodes::Block[*s] }
    end

    def variable_statement(tokens)
      return nil unless try_consume_token(tokens, Tokens::VAR)

      decls = {}
      begin
        name = consume_token(tokens, Tokens::IDENTIFIER).value
        init = if try_consume_token(tokens, Tokens::ASSIGN)
                 expression(tokens, COMMA_BINDING_POWER)
               else
                 nil
               end
        decls[name] = init
      end while try_consume_token(tokens, Tokens::COMMA)

      consume_token(tokens, Tokens::SEMICOLON)
      Nodes::VariableStatement[decls]
    end

    def function_declaration(tokens)
      return nil unless try_consume_token(tokens, Tokens::FUNCTION)
      name = consume_token(tokens, Tokens::IDENTIFIER).value
      args = []
      consume_token(tokens, Tokens::OPEN_PAREN)
      unless try_consume_token(tokens, Tokens::CLOSE_PAREN)
        begin
          args << consume_token(tokens, Tokens::IDENTIFIER).value
        end while try_consume_token(tokens, Tokens::COMMA)
        consume_token(tokens, Tokens::CLOSE_PAREN)
      end
      consume_token(tokens, Tokens::OPEN_BRACE)
      statement_list(tokens, Tokens::CLOSE_BRACE) { |s|
        Nodes::FunctionDeclaration[name, args, *s]
      }
    end

    def statement(tokens)
      empty_statement(tokens) || block_statement(tokens) ||
      variable_statement(tokens) || function_declaration(tokens) ||
      expression_statement(tokens)
    end

    def statement_list(tokens, terminator)
      statements = []
      until try_consume_token(tokens, terminator)
        ast = statement(tokens)
        statements << ast unless Nodes::EmptyStatement === ast
      end
      yield statements
    end

    def program(tokens)
      statement_list(tokens, Tokens::EOF) { |s| Nodes::Program[*s] }
    end

    def consume_token(tokens, kind)
      tokens.next while Tokens::LINE_BREAK === tokens.peek
      token = tokens.peek
      unless kind === token
        if kind === Tokens::SEMICOLON
          case token
          when Tokens::EOF, Tokens::CLOSE_BRACE
            return Tokens::SEMICOLON
          end
        end
        raise ParseError, "Expected #{kind} but got #{token}"
      end
      tokens.next
    end

    def try_consume_token(tokens, kind)
      tokens.next while Tokens::LINE_BREAK === tokens.peek
      if kind === tokens.peek
        tokens.next
      else
        nil
      end
    end
  end

  include Grammar

  def self.parse(string)
    tokens = Lexer.scan(string)
    new.program(tokens)
  end

  def self.parse_expression(string)
    tokens = Lexer.scan(string)
    new.expression(tokens, Grammar::MIN_BINDING_POWER)
  end
end

end
