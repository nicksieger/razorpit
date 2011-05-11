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

  class String < LiteralNode
  end

  class RegEx < LiteralNode
  end

  class Identifier < Node
    attr_reader :name

    def initialize(name)
      @name = name.to_sym
    end

    def ==(other)
      self.class == other.class && self.name == other.name
    end
  end

  class Program < Node
    def ==(other)
      self.class == other.class
    end
  end

  class NamedPropertyAccess < Node
    attr_reader :lhs
    attr_reader :name

    def initialize(lhs, name)
      @lhs = lhs
      @name = name.to_sym
    end

    def ==(other)
      self.class == other.class &&
      self.lhs == other.lhs &&
      self.name == other.name
    end
  end

  class DynamicPropertyAccess < BinaryOpNode
  end

  class Condition < Node
    attr_reader :predicate, :then_expr, :else_expr

    def initialize(predicate, then_expr, else_expr)
      @predicate = predicate
      @then_expr = then_expr
      @else_expr = else_expr
    end

    def ==(other)
      self.class == other.class and
      self.predicate == other.predicate and
      self.then_expr == other.then_expr and
      self.else_expr == other.else_expr
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

  class And < BinaryOpNode
  end

  class Or < BinaryOpNode
  end

  class BitwiseAnd < BinaryOpNode
  end

  class BitwiseOr < BinaryOpNode
  end

  class BitwiseXOr < BinaryOpNode
  end

  class GreaterThan < BinaryOpNode
  end

  class LessThan < BinaryOpNode
  end

  class GreaterThanOrEqual < BinaryOpNode
  end

  class LessThanOrEqual < BinaryOpNode
  end

  class Equal < BinaryOpNode
  end

  class NotEqual < BinaryOpNode
  end

  class StrictlyEqual < BinaryOpNode
  end

  class StrictlyNotEqual < BinaryOpNode
  end

  class LeftShift < BinaryOpNode
  end

  class SignedRightShift < BinaryOpNode
  end

  class UnsignedRightShift < BinaryOpNode
  end

  class Assign < BinaryOpNode
  end

  class AddAssign < BinaryOpNode
  end

  class SubtractAssign < BinaryOpNode
  end

  class MultiplyAssign < BinaryOpNode
  end

  class DivideAssign < BinaryOpNode
  end

  class ModulusAssign < BinaryOpNode
  end

  class LeftShiftAssign < BinaryOpNode
  end

  class SignedRightShiftAssign < BinaryOpNode
  end

  class UnsignedRightShiftAssign < BinaryOpNode
  end

  class BitwiseAndAssign < BinaryOpNode
  end

  class BitwiseXOrAssign < BinaryOpNode
  end

  class BitwiseOrAssign < BinaryOpNode
  end

  class UnaryPlus < UnaryOpNode
  end

  class UnaryMinus < UnaryOpNode
  end

  class PreIncrement < UnaryOpNode
  end

  class PostIncrement < UnaryOpNode
  end

  class PreDecrement < UnaryOpNode
  end

  class PostDecrement < UnaryOpNode
  end

  class TypeOf < UnaryOpNode
  end

  class Void < UnaryOpNode
  end

  class Not < UnaryOpNode
  end

  class BitwiseNot < UnaryOpNode
  end

  class Sequence < BinaryOpNode
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
