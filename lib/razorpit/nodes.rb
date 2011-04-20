module RazorPit

class Node
  class << self
    alias_method :[], :new
  end

  def ==(other)
    false
  end
end

module Nodes
  class Number < Node
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def ==(other)
      self.class == other.class && self.value == other.value
    end
  end

  class Program < Node
    def ==(other)
      self.class == other.class
    end
  end

  class Add < Node
    attr_reader :lhs, :rhs

    def initialize(lhs, rhs)
      @lhs = lhs
      @rhs = rhs
    end

    def ==(other)
      self.class == other.class &&
      self.lhs == other.lhs &&
      self.rhs == other.rhs
    end
  end
end

end
