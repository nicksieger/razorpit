require 'razorpit/tokens'

module RazorPit

class Lexer
  include Enumerable

  class InvalidToken < Exception
  end

  class Producer
    include Enumerable

    def initialize(string)
      @string = string
      @infix = false
      @offset = 0
      @peeked = nil
    end

    def next
      raise StopIteration, "stop" if @eof

      if @peeked
        peeked, @peeked = @peeked, nil
        return peeked
      end

      loop do
        unless @offset == @string.length
          token, new_offset = if @infix
                                Tokens.match_infix_token(@string, @offset)
                              else
                                Tokens.match_prefix_token(@string, @offset)
                              end

          case token
          when Tokens::INVALID
            raise InvalidToken, "invalid token at offset #{@offset}"
          when Tokens::WHITESPACE
            # ignore
          else
            return token
          end

          @offset = new_offset
        else
          @eof = true
          return Tokens::EOF
        end
      end
    end

    def peek
      @peeked = self.next
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
      begin
        loop { yield self.next }
      rescue StopIteration
      end
    end
  end

  def initialize(string)
    @producer = Producer.new(string)
  end

  def with_infix(&block)
    @producer.with_infix(&block)
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
