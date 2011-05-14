require 'razorpit/tokens'

module RazorPit

class Lexer
  include Enumerable

  class InvalidToken < Exception
  end

  def self.scan(string)
    lexer = new(string)
    if block_given?
      lexer.each { |token| yield token }
      self
    else
      lexer.each
    end
  end

  def initialize(string)
    @string = string
    @infix = false
  end

  def with_infix(infix)
    saved_infix = @infix
    @infix = infix
    begin
      yield
    ensure
      @infix = saved_infix
    end
  end

  def each
    return enum_for(:each) unless block_given?

    offset = 0

    until offset == @string.length
      token, new_offset = if @infix
                            Tokens.match_infix_token(@string, offset)
                          else
                            Tokens.match_prefix_token(@string, offset)
                          end

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
