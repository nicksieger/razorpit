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
      token_class.re = re
      token_class.value_fn = value_fn || IDENTITY_FN
      const_set(name, token_class)
    end

    define_token(:NUMBER, /(?<value>\d+)/) { |value| value.to_f }
    define_token(:PLUS, /\+/)
  end

  TOKEN_NAMES = Tokens.constants
  subexpressions = TOKEN_NAMES.map { |token_name|
    token_class = Tokens.const_get(token_name)
    "(?<#{token_name}>#{token_class.re.source})"
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
