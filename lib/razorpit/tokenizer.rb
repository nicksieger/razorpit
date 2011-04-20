require 'razorpit/tokens'

module RazorPit

module Tokenizer
  extend self

  class InvalidToken < Exception
  end

  def tokenize(string)
    return enum_for(:tokenize, string) unless block_given?

    offset = 0

    until offset == string.length
      m = TOKENS_REGEXP.match(string, offset)
      raise InvalidToken, "invalid token at offset #{offset}" if m['INVALID']

      token = SIMPLE_TOKENS[m[0]]
      unless token
        COMPLEX_TOKENS.each do |name, token_class|
          if m[name]
            token = token_class.build(m['value'])
            break
          end
        end
      end

      yield token unless Tokens::WHITESPACE === token
      offset = m.end(0)
    end

    self
  end
end

end
