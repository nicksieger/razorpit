require 'razorpit/tokens'
require 'razorpit/lexer'
require 'razorpit/nodes'

module RazorPit

class ParseError < RuntimeError
end

class Parser
  def initialize(lexer)
    @lexer = lexer
    @line_break = false
  end

  def self.parse(string)
    lexer = Lexer.new(string)
    new(lexer).program
  end

  def self.parse_expression(string)
    lexer = Lexer.new(string)
    new(lexer).expression(MIN_BINDING_POWER)
  end

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

  def self.define_literal(token_type, ast_class)
    token_type.left_binding_power = MAX_BINDING_POWER
    token_type.token_class_eval do
      include PrefixToken
      eval <<-EOS
        def prefix(parser)
          #{ast_class}[value]
        end
      EOS
    end
    self
  end

  def self.define_infix(token_type, ast_class, binding_power)
    token_type.left_binding_power = binding_power
    token_type.token_class_eval do
      include SuffixToken
      eval <<-EOS
        def suffix(parser, lhs)
          rhs = parser.expression(#{binding_power})
          #{ast_class}[lhs, rhs]
        end
      EOS
    end
  end

  def self.define_prefix(token_type, ast_class, binding_power)
    token_type.token_class_eval do
      include PrefixToken
      eval <<-EOS
        def prefix(parser)
          expr = parser.expression(#{binding_power})
          #{ast_class}[expr]
        end
      EOS
    end
  end

  Tokens::PERIOD.left_binding_power = MEMBER_BINDING_POWER
  Tokens::PERIOD.token_class_eval do
    include SuffixToken
    def suffix(parser, lhs)
      name = parser.consume_token(Tokens::IDENTIFIER)
      Nodes::PropertyAccess[lhs, Nodes::String[name.value]]
    end
  end

  Tokens::OPEN_BRACKET.left_binding_power = MEMBER_BINDING_POWER
  Tokens::OPEN_BRACKET.token_class_eval do
    include SuffixToken
    def suffix(parser, lhs)
      rhs = parser.expression(MEMBER_BINDING_POWER)
      parser.consume_token(Tokens::CLOSE_BRACKET)
      Nodes::PropertyAccess[lhs, rhs]
    end
  end

  Tokens::INCREMENT.left_binding_power = INCREMENT_BINDING_POWER
  Tokens::INCREMENT.token_class_eval do
    include PrefixToken 
    include SuffixToken

    def prefix(parser)
      expr = parser.expression(INCREMENT_BINDING_POWER)
      Nodes::PreIncrement[expr]
    end

    def suffix(parser, lhs)
      Nodes::PostIncrement[lhs]
    end
  end

  Tokens::DECREMENT.left_binding_power = INCREMENT_BINDING_POWER
  Tokens::DECREMENT.token_class_eval do
    include PrefixToken 
    include SuffixToken

    def prefix(parser)
      expr = parser.expression(INCREMENT_BINDING_POWER)
      Nodes::PreDecrement[expr]
    end

    def suffix(parser, lhs)
      Nodes::PostDecrement[lhs]
    end
  end

  Tokens::OPEN_PAREN.left_binding_power = CALL_BINDING_POWER
  Tokens::OPEN_PAREN.token_class_eval do
    include PrefixToken 
    include SuffixToken

    def prefix(parser)
      expr = parser.expression(MIN_BINDING_POWER)
      parser.consume_token(Tokens::CLOSE_PAREN)
      expr
    end

    def suffix(parser, lhs)
      args = []
      unless parser.try_consume_token(Tokens::CLOSE_PAREN)
        begin
          args << parser.expression(COMMA_BINDING_POWER)
        end while parser.try_consume_token(Tokens::COMMA)
        parser.consume_token(Tokens::CLOSE_PAREN)
      end
      Nodes::FunctionCall[lhs, *args]
    end
  end

  Tokens::QUESTION.left_binding_power = CONDITION_BINDING_POWER
  Tokens::QUESTION.token_class_eval do
    include SuffixToken
    def suffix(parser, lhs)
      this_expr = parser.expression(COMMA_BINDING_POWER)
      parser.consume_token(Tokens::COLON)
      else_expr = parser.expression(COMMA_BINDING_POWER)
      Nodes::Condition[lhs, this_expr, else_expr]
    end
  end

  Tokens::NULL.left_binding_power = MAX_BINDING_POWER
  Tokens::NULL.token_class_eval do
    include PrefixToken
    def prefix(parser)
      Nodes::NULL
    end
  end

  define_literal(Tokens::NUMBER, Nodes::Number)
  define_literal(Tokens::BOOLEAN, Nodes::Boolean)
  define_literal(Tokens::STRING, Nodes::String)
  define_literal(Tokens::REGEXP, Nodes::RegExp)
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

  class << self
    # done with these
    undef define_literal
    undef define_prefix
    undef define_infix
  end

  def left_binding_power(token)
    token.left_binding_power || MIN_BINDING_POWER
  end

  def try_expression(right_binding_power)
    try_function_expression ||
    @lexer.with_infix(false) do
      token = try_consume_token(PrefixToken)
      break unless token
      ast = token.prefix(self)
      @lexer.with_infix(true) do
        loop do
          token = try_consume_token(Proc.new { |t|
            SuffixToken === t and
            left_binding_power(t) > right_binding_power
          })
          break unless token
          ast = token.suffix(self, ast)
        end
      end
      ast
    end
  end

  def expression(right_binding_power)
    try_expression(right_binding_power) || error
  end

  def try_empty_statement
    return nil unless try_consume_token(Tokens::SEMICOLON)
    Nodes::EmptyStatement[]
  end

  def expression_statement
    ast = expression(MIN_BINDING_POWER)
    consume_token(Tokens::SEMICOLON)
    ast
  end

  def try_control_statement
    if try_consume_token(Tokens::RETURN)
      ast = if consume_line_break
              nil
            else
              try_expression(MIN_BINDING_POWER)
            end
      Nodes::Return[ast]
    elsif try_consume_token(Tokens::CONTINUE)
      consume_token(Tokens::SEMICOLON)
      Nodes::Continue[]
    elsif try_consume_token(Tokens::BREAK)
      consume_token(Tokens::SEMICOLON)
      Nodes::Break[]
    else
      nil
    end
  end

  def try_block_statement
    return nil unless try_consume_token(Tokens::OPEN_BRACE)
    statement_list(Tokens::CLOSE_BRACE) { |s| Nodes::Block[*s] }
  end

  def try_if_statement
    return nil unless try_consume_token(Tokens::IF)
    consume_token(Tokens::OPEN_PAREN)
    predicate = expression(MIN_BINDING_POWER)
    consume_token(Tokens::CLOSE_PAREN)
    then_clause = statement
    else_clause = if try_consume_token(Tokens::ELSE)
                    statement
                  else
                    nil
                  end
    Nodes::If[predicate, then_clause, else_clause]
  end

  def try_loop_statement
    if try_consume_token(Tokens::DO)
      body = statement
      consume_token(Tokens::WHILE)
      consume_token(Tokens::OPEN_PAREN)
      predicate = expression(MIN_BINDING_POWER)
      consume_token(Tokens::CLOSE_PAREN)
      consume_token(Tokens::SEMICOLON)
      Nodes::DoWhile[body, predicate]
    elsif try_consume_token(Tokens::WHILE)
      consume_token(Tokens::OPEN_PAREN)
      predicate = expression(MIN_BINDING_POWER)
      consume_token(Tokens::CLOSE_PAREN)
      body = statement
      Nodes::While[predicate, body]
    elsif try_consume_token(Tokens::FOR)
      consume_token(Tokens::OPEN_PAREN)
      init = try_variable_statement
      unless init
        init = try_expression(MIN_BINDING_POWER)
        consume_token(Tokens::SEMICOLON)
      end
      predicate = try_expression(MIN_BINDING_POWER)
      consume_token(Tokens::SEMICOLON)
      incr = try_expression(MIN_BINDING_POWER)
      consume_token(Tokens::CLOSE_PAREN)
      body = statement
      Nodes::For[init, predicate, incr, body]
    else
      nil
    end
  end

  def try_variable_statement
    return nil unless try_consume_token(Tokens::VAR)

    decls = {}
    begin
      name = consume_token(Tokens::IDENTIFIER).value
      init = if try_consume_token(Tokens::ASSIGN)
               expression(COMMA_BINDING_POWER)
             else
               nil
             end
      decls[name] = init
    end while try_consume_token(Tokens::COMMA)

    consume_token(Tokens::SEMICOLON)
    Nodes::VariableStatement[decls]
  end

  def try_function_definition(name_required)
    return nil unless try_consume_token(Tokens::FUNCTION)
    name = try_consume_token(Tokens::IDENTIFIER)
    if name
      name = name.value
    elsif name_required
      raise ParseError, "missing function name"
    end
    args = []
    consume_token(Tokens::OPEN_PAREN)
    unless try_consume_token(Tokens::CLOSE_PAREN)
      begin
        args << consume_token(Tokens::IDENTIFIER).value
      end while try_consume_token(Tokens::COMMA)
      consume_token(Tokens::CLOSE_PAREN)
    end
    consume_token(Tokens::OPEN_BRACE)
    statement_list(Tokens::CLOSE_BRACE) { |s|
      yield name, args, s
    }
  end

  def try_function_expression
    try_function_definition(false) do |name, args, s|
      Nodes::Function[name, args, *s]
    end
  end

  def try_function_declaration
    try_function_definition(true) do |name, args, s|
      Nodes::FunctionDeclaration[name, args, *s]
    end
  end

  def statement
    @lexer.with_infix(false) do
      try_empty_statement || try_control_statement ||
      try_if_statement || try_loop_statement ||
      try_block_statement || try_variable_statement ||
      try_function_declaration || expression_statement
    end
  end

  def statement_list(terminator)
    statements = []
    until try_consume_token(terminator)
      ast = statement
      statements << ast unless Nodes::EmptyStatement === ast
    end
    yield statements
  end

  def program
    statement_list(Tokens::EOF) { |s| Nodes::Program[*s] }
  end

  def consume_line_break
    lookahead_token
    result = @line_break
    @line_break = false
    result
  end

  def lookahead_token
    token = @lexer.peek
    case token
    when Tokens::LINE_BREAK
      @line_break = true
      @lexer.next
      @lexer.peek
    else
      token
    end
  end

  def advance_token(override=nil)
    @line_break = false
    override || @lexer.next
  end

  def error
    raise ParseError, "Unexpected token #{lookahead_token}"
  end

  def consume_token(kind)
    token = lookahead_token
    case token
    when kind
      return advance_token
    when Tokens::EOF, Tokens::CLOSE_BRACE, Proc.new { @line_break }
      return advance_token(Tokens::SEMICOLON) if kind === Tokens::SEMICOLON
    end
    raise ParseError, "Expected #{kind} but got #{token}"
  end

  def try_consume_token(kind)
    if kind === lookahead_token
      advance_token
    else
      nil
    end
  end
end

end
