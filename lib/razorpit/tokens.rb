module RazorPit

module TokenType
  attr_reader :re

  def build(value)
    raise NotImplementedError, "#{self.class}#build not implemented"
  end

  def token_class_eval(&block)
    raise NotImplementedError, "#{self.class}#token_class_eval not implemented"
  end
end

module Token
  def token_type
    raise NotImplementedError, "#{self.class}#token_type not implemented"
  end
end

ValueToken = Struct.new :value do
  include Token

  class << self
    include TokenType

    IDENTITY_FN = lambda { |v| v }

    def derive(re, value_fn)
      Class.new self do
        @re = re
        @value_fn = value_fn || IDENTITY_FN
      end
    end

    def build(value)
      new(@value_fn.call(value))
    end

    alias_method :token_class_eval, :class_eval
  end

  alias_method :token_type, :class
end

class SingletonToken
  include Token
  include TokenType

  def initialize(name, re)
    @name = name
    @re = re
  end

  def build(value)
    self
  end

  def token_type
    self
  end

  def token_class_eval(&block)
    eigenclass = class << self; self; end
    eigenclass.class_eval(&block)
  end

  def to_s
    "RazorPit::Tokens::#{@name}"
  end
  alias_method :inspect, :to_s
end

module Tokens
  extend self

  # tokens which are identified by value
  @simple_tokens = {}
  # tokens which are identified by capture name
  @complex_tokens = {}

  def define_token(name, pattern, &value_fn)
    re = case pattern
         when String
           /(?:#{Regexp.quote(pattern)})/
         else
           /(?<#{name}>#{pattern})/
         end

    token_type = if re.names.include? 'value'
                   ValueToken.derive(re, value_fn)
                 else
                   SingletonToken.new(name, re)
                 end

    case pattern
    when String
      @simple_tokens[pattern] = token_type
    else
      @complex_tokens[name] = token_type
    end

    const_set(name, token_type)
  end

  def define_keyword(*keywords)
    keywords.each do |keyword|
      name = keyword.upcase.intern
      define_token(name, keyword)
    end
  end

  define_token(:INVALID, /(?<value>.)/)
  define_token(:WHITESPACE, /\s+/)
  define_token(:LINE_BREAK, /(?:[\u000A\u000D\u2028\u2029]+\s*)+/)
  define_token(:EOF, /\Z/)

  # punctuators
  define_token(:PLUS, '+')
  define_token(:MINUS, '-')
  define_token(:TIMES, '*')
  define_token(:DIV, '/')
  define_token(:COLON, ':')
  define_token(:SEMICOLON, ';')
  define_token(:PERIOD, '.')
  define_token(:COMMA, ',')
  define_token(:OPEN_BRACE, '{')
  define_token(:CLOSE_BRACE, '}')
  define_token(:OPEN_BRACKET, '[')
  define_token(:CLOSE_BRACKET, ']')
  define_token(:OPEN_PAREN, '(')
  define_token(:CLOSE_PAREN, ')')
  define_token(:GT, '>')
  define_token(:LT, '<')
  define_token(:MODULUS, '%')
  define_token(:NOT, '!')
  define_token(:ASSIGN, '=')
  define_token(:QUESTION, '?')

  define_token(:BITWISE_NOT, '~')
  define_token(:BITWISE_XOR, '^')
  define_token(:BITWISE_AND, '&')
  define_token(:BITWISE_OR, '|')

  define_token(:NOT_EQUAL, '!=')
  define_token(:EQUAL, '==')
  define_token(:GTE, '>=')
  define_token(:LTE, '<=')
  define_token(:STRICT_EQUAL, '===')
  define_token(:STRICT_NOT_EQUAL, '!==')

  define_token(:SHIFT_LEFT, '<<')
  define_token(:SHIFT_RIGHT_EXTEND, '>>')
  define_token(:SHIFT_RIGHT, '>>>')

  define_token(:INCREMENT, '++')
  define_token(:DECREMENT, '--')

  define_token(:AND, '&&')
  define_token(:OR, '||')

  define_token(:PLUS_ASSIGN, '+=')
  define_token(:MINUS_ASSIGN, '-=')
  define_token(:TIMES_ASSIGN, '*=')
  define_token(:DIV_ASSIGN, '/=')
  define_token(:MODULUS_ASSIGN, '%=')
  define_token(:BITWISE_OR_ASSIGN, '|=')
  define_token(:BITWISE_AND_ASSIGN, '&=')
  define_token(:BITWISE_XOR_ASSIGN, '^=')
  define_token(:SHIFT_LEFT_ASSIGN, '<<=')
  define_token(:SHIFT_RIGHT_EXTEND_ASSIGN, '>>=')
  define_token(:SHIFT_RIGHT_ASSIGN, '>>>=')

  decimal_literal = /(?:
    (?: (?: 0 | [1-9][0-9]* ) (?: \.[0-9]* )? | \.[0-9]+ )
    (?: e [+-]?[0-9]+ )?
  )/xi
  hex_integer_literal = /(?:0x[0-9a-f]+)/i
  numeric_literal = "#{hex_integer_literal}|#{decimal_literal}"
  define_token(:NUMBER, /(?<value>#{numeric_literal})/) do |value|
    if value =~ /^0x/i
      value[2..-1].to_i(16).to_f
    else
      value.to_f
    end
  end
  define_token(:IDENTIFIER, /(?<value>[a-z_$][a-z0-9_$]*)/i)
  define_token(:STRING, /(?:'(?<value>[^']*)'|"(?<value>[^"]*)")/)
  define_token(:REGEXP, /\/(?<value>[^\/]*\/[a-z0-9_$]*)/) do |value|
    value =~ %r!(.*)/([^/]*)$!
    [$1, $2]
  end

  # keywords, etc.
  define_token(:BOOLEAN, /(?<value>true|false)/) { |value| value == "true" }
  define_keyword('null')
  define_keyword *%w(break case catch continue debugger default delete do
                     else finally for function if in instanceof new return
                     switch this throw try typeof var void while with)

  # reserved words
  define_keyword *%w(class const enum export extends import super)

  # we're done with these now
  undef define_token
  undef define_keyword

  # reverse to put later-defined tokens first (i.e. higher priority)
  subexpressions = constants.reverse.map { |token_name|
    const_get(token_name).re
  }
  @tokens_regexp = Regexp.compile("#{subexpressions.join("|")}")

  def match_token(string, offset)
    m = @tokens_regexp.match(string, offset)
    new_offset = m.end(0)
    token = @simple_tokens[m[0]]
    unless token
      @complex_tokens.each do |name, token_type|
        if m[name]
          token_value = m['value']
          token = token_type.build(token_value)
          break
        end
      end
    end
    return token, new_offset
  end
end

end
