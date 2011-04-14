module RazorPit

module Tokenizer
  extend self

  BaseTokens = Struct.new :value

  module Tokens
    NUMBER = Class.new BaseTokens
    PLUS = Class.new BaseTokens
  end

  TOKENS_REGEXP = %r{
    (?<number>(?<value>\d+)) |
    (?<plus>\+)
  }x

  def tokenize(string)
    tokens = []

    m = TOKENS_REGEXP.match(string)
    if m
      value = m['value']
      case
      when m['number']
        token = Tokens::NUMBER[value.to_f]
      when m['plus']
        token = Tokens::PLUS[]
      end
      tokens << token
    end

    tokens
  end
end

end
