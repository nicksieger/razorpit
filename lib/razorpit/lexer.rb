require 'razorpit/tokens'

module RazorPit

class Lexer
  class InvalidToken < Exception
  end

  def self.scan(string)
    lexer = new(string)
    if block_given?
      lexer.scan { |token| yield token }
      self
    else
      lexer.scan
    end
  end

  def initialize(string)
    @string = string
  end

  def scan
    return enum_for(:scan) unless block_given?

    offset = 0

    until offset == @string.length
      token, new_offset = Tokens.match_token(@string, offset)

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

    yield Tokens::EOF

    self
  end
end

end
