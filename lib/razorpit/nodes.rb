module RazorPit

class Node
  class << self
    alias_method :[], :new
  end

  def ==(other)
    false
  end
end

class LiteralNode < Node
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def ==(other)
    self.class == other.class && self.value == other.value
  end
end

module Nodes
  class Number < LiteralNode
  end

  class Boolean < LiteralNode
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

  class UnaryPlus < Node
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def ==(other)
      self.class == other.class &&
      self.expr == other.expr
    end
  end
end

end
