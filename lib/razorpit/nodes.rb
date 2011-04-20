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

class UnaryOpNode < Node
  attr_reader :expr

  def initialize(expr)
    @expr = expr
  end

  def ==(other)
    self.class == other.class &&
    self.expr == other.expr
  end
end

class BinaryOpNode < Node
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

  class Add < BinaryOpNode
  end

  class Subtract < BinaryOpNode
  end

  class Multiply < BinaryOpNode
  end

  class Divide < BinaryOpNode
  end

  class Modulus < BinaryOpNode
  end

  class UnaryPlus < UnaryOpNode
  end

  class UnaryMinus < UnaryOpNode
  end

  class TypeOf < UnaryOpNode
  end

  class Void < UnaryOpNode
  end

  NULL = Node.new
  class << NULL
    def ==(other)
      self.equal? other
    end

    def to_s
      "RazorPit::Nodes::NULL"
    end
    alias_method :inspect, :to_s
  end
end

end
