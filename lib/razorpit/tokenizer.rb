module RazorPit

module Tokenizer
  extend self

  BaseToken = Struct.new :value do
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
    attr_reader :value

    def initialize(re)
      @value = re
      @re = Regexp.quote(re)
    end

    def build(value)
      self
    end
  end

  module Tokens
    extend self

  private
    def define_token(name, re, &value_fn)
      
      case re
      when String
        token_type = SingletonToken.new(re)
      else
        token_type = BaseToken.derive(re, value_fn)
      end
      const_set(name, token_type)
    end

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

    # complex tokens
    define_token(:NUMBER, /(?<value>\d+)/) { |value| value.to_f }
    define_token(:BOOLEAN, /(?<value>true|false)/) { |value| value == "true" }
  end

  TOKEN_NAMES = Tokens.constants
  # reverse to give later tokens higher priority
  subexpressions = TOKEN_NAMES.reverse.map { |token_name|
    token_class = Tokens.const_get(token_name)
    "(?<#{token_name}>#{token_class.re})"
  }
  TOKENS_REGEXP = Regexp.compile(subexpressions.join("|"))

  def tokenize(string)
    tokens = []
    offset = 0

    until offset == string.length
      m = TOKENS_REGEXP.match(string, offset)

      token_name = TOKEN_NAMES[TOKEN_NAMES.index { |n| m[n] }]
      token_type = Tokens.const_get(token_name)
      token = token_type.build(m['value'])

      tokens << token
      offset = m.end(0)
    end

    tokens
  end
end

end
