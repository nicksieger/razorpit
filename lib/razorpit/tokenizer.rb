module RazorPit

module Tokenizer
  extend self

  BaseToken = Struct.new :value do
    class << self
      attr_accessor :re, :value_fn

      def build(value)
        new(@value_fn.call(value))
      end
    end
  end

  IDENTITY_FN = lambda { |v| v }

  module Tokens
    extend self

  private
    def define_token(name, re, &value_fn)
      token_class = Class.new BaseToken
      
      token_class.re = case re
                       when String; Regexp.quote(re)
                       else; re
                       end
      token_class.value_fn = value_fn || IDENTITY_FN
      const_set(name, token_class)
    end

    # punctuators
    define_token(:PLUS, '+')
    define_token(:MINUS, '-')
    define_token(:TIMES, '*')
    define_token(:DIVISION, '/')
    define_token(:COLON, ':')
    define_token(:SEMICOLON, ';')
    define_token(:PERIOD, '.')
    define_token(:COMMA, ',')
    define_token(:OBRACE, '{')
    define_token(:CBRACE, '}')
    define_token(:OBRACKET, '[')
    define_token(:CBRACKET, ']')
    define_token(:OPAREN, '(')
    define_token(:CPAREN, ')')
    define_token(:GT, '>')
    define_token(:LT, '<')

    define_token(:BITWISE_XOR, '^')
    define_token(:BITWISE_AND, '&')
    define_token(:BITWISE_OR, '|')

    define_token(:NEQUAL, '!=')
    define_token(:EQUAL, '==')
    define_token(:GTE, '>=')
    define_token(:LTE, '<=')

    # complex tokens
    define_token(:NUMBER, /(?<value>\d+)/) { |value| value.to_f }
  end

  # reverse to give later tokens higher priority
  TOKEN_NAMES = Tokens.constants.reverse
  subexpressions = TOKEN_NAMES.map { |token_name|
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
      token_class = Tokens.const_get(token_name)

      value = m['value']
      token = token_class.build(value)

      tokens << token
      offset = m.end(0)
    end

    tokens
  end
end

end
