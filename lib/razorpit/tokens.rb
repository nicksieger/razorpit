module RazorPit

ValueToken = Struct.new :value do
  IDENTITY_FN = lambda { |v| v }

  class << self
    attr_accessor :re, :value_fn

    def derive(re, value_fn)
      c = Class.new self
      c.re = re
      c.value_fn = value_fn || IDENTITY_FN
      c
    end

    def build(value)
      new(@value_fn.call(value))
    end
  end
end

class SingletonToken
  attr_reader :re

  def initialize(name, re)
    @name = name
    @re = re
  end

  def value
    nil
  end

  def build(value)
    self
  end
end

SIMPLE_TOKENS = {}
COMPLEX_TOKENS = {}

module Tokens
  extend self

private
  def define_token(name, pattern, &value_fn)
    case pattern
    when String
      re = /(?:#{Regexp.quote(pattern)})/
      token_type = SingletonToken.new(name, re)
      SIMPLE_TOKENS[pattern] = token_type
    else
      re = /(?<#{name}>#{pattern})/
      token_type = ValueToken.derive(re, value_fn)
      COMPLEX_TOKENS[name] = token_type
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
  define_token(:STRICT_NOT_EQUAL, '!===')

  define_token(:SHIFT_LEFT, '<<')
  define_token(:SHIFT_RIGHT, '>>')
  define_token(:SHIFT_RIGHT_EXTEND, '>>>')

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
  define_token(:SHIFT_RIGHT_ASSIGN, '>>=')
  define_token(:SHIFT_RIGHT_EXTEND_ASSIGN, '>>>=')

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

  # keywords, etc.
  define_token(:BOOLEAN, /(?<value>true|false)/) { |value| value == "true" }
  define_keyword('null')
  define_keyword *%w(break case catch continue debugger default delete do
                     else finally for function if in instanceof new return
                     switch this throw try typeof var void while with)

  # reserved words
  define_keyword *%w(class const enum export extends import super)
end

# reverse to give later tokens higher priority
subexpressions = Tokens.constants.reverse.map { |token_name|
  token_class = Tokens.const_get(token_name)
  "(?<#{token_name}>#{token_class.re})"
}
TOKENS_REGEXP = Regexp.compile("#{subexpressions.join("|")}")

end
