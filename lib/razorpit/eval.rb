require 'razorpit/nodes'

module RazorPit

NULL = Object.new
class << NULL
  def to_s
    RazorPit::NULL
  end
  alias_method :inspect, :to_s
end

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
    lresult = lhs.evaluate
    rresult = rhs.evaluate
    if String === lresult or String === rresult
      "#{Eval.stringify(lresult)}#{Eval.stringify(rresult)}"
    else
      lresult + rresult
    end
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

Nodes::TypeOf.class_eval do
  def evaluate
    result = expr.evaluate
    case result
    when Numeric
      "number"
    when String
      "string"
    when nil
      "undefined"
    else
      "object"
    end
  end
end

Nodes::Not.class_eval do
  def evaluate
    result = expr.evaluate
    case result
    when true, false, nil
      !result
    when Numeric
      result == 0
    when String
      result.empty?
    when RazorPit::NULL
      true
    else
      false
    end
  end
end

Nodes::Void.class_eval do
  def evaluate
    nil
  end
end

class << Nodes::NULL
  def evaluate
    RazorPit::NULL
  end
end

module Eval
extend self

def stringify(obj)
  case obj
  when Numeric
    as_int = obj.to_i
    if as_int == obj
      as_int.to_s
    else
      obj.to_s
    end
  else
    obj.to_s
  end
end

end
end
