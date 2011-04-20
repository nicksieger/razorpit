require 'razorpit/nodes'

module RazorPit

NULL = Object.new
class << NULL
  def to_s
    RazorPit::NULL
  end
  alias_method :inspect, :to_s
end

module Eval

LiteralNode.class_eval do
  def evaluate
    value
  end
end

Nodes::UnaryPlus.class_eval do
  def evaluate
    expr.evaluate
  end
end

Nodes::UnaryMinus.class_eval do
  def evaluate
    -expr.evaluate
  end
end

Nodes::Add.class_eval do
  def evaluate
    lhs.evaluate + rhs.evaluate
  end
end

Nodes::Subtract.class_eval do
  def evaluate
    lhs.evaluate - rhs.evaluate
  end
end

Nodes::Multiply.class_eval do
  def evaluate
    lhs.evaluate * rhs.evaluate
  end
end

Nodes::Divide.class_eval do
  def evaluate
    lhs.evaluate / rhs.evaluate
  end
end

Nodes::Modulus.class_eval do
  def evaluate
    lhs.evaluate % rhs.evaluate
  end
end

class << Nodes::NULL
  def evaluate
    RazorPit::NULL
  end
end

end
end
