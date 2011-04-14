module RazorPit

module Tokenizer
  BaseToken = Struct.new :value

  module Tokens
    NUMBER = Class.new BaseToken
    PLUS = Class.new BaseToken
  end

  TOKENS_REGEXP = %r{
    (?<number>(?<value>\d+)) |
    (?<plus>\+)
  }x

  def self.tokenize(string)
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
