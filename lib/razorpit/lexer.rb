require 'razorpit/tokens'

module RazorPit

class Lexer
  include Enumerable

  class InvalidToken < Exception
  end

  def initialize(string)
    @string = string
    @infix = false
    @producer = produce
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

  def produce
    return enum_for(:produce) unless block_given?

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

  def next
    @producer.next
  end

  def peek
    @producer.peek
  end

  def each
    if block_given?
      @producer.each { |token| yield token }
    else
      @producer.each
    end
  end
end

end
