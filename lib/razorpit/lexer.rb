require 'razorpit/tokens'

module RazorPit

module Lexer
  extend self

  class InvalidToken < Exception
  end

  def scan(string)
    return enum_for(:scan, string) unless block_given?

    offset = 0

    until offset == string.length
      token, new_offset = Tokens.match_token(string, offset)

      case token
      when Tokens::INVALID
        raise InvalidToken, "invalid token at offset #{offset}"
      when Tokens::WHITESPACE
        # ignore
      else
        yield token
      end

      offset = new_offset
    end

    self
  end
end

end
