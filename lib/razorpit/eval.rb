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
      "#{Eval.to_string(lresult)}#{Eval.to_string(rresult)}"
    else
      Eval.to_number(lresult) + Eval.to_number(rresult)
    end
  end
end

Nodes::Subtract.class_eval do
  def evaluate
    Eval.to_number(lhs.evaluate) - Eval.to_number(rhs.evaluate)
  end
end

Nodes::Multiply.class_eval do
  def evaluate
    Eval.to_number(lhs.evaluate) * Eval.to_number(rhs.evaluate)
  end
end

Nodes::Divide.class_eval do
  def evaluate
    Eval.to_number(lhs.evaluate) / Eval.to_number(rhs.evaluate)
  end
end

Nodes::Modulus.class_eval do
  def evaluate
    Eval.to_number(lhs.evaluate) % Eval.to_number(rhs.evaluate)
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
    !Eval.to_boolean(result)
  end
end

Nodes::And.class_eval do
  def evaluate
    left = lhs.evaluate
    return left unless Eval.to_boolean(left)
    rhs.evaluate
  end
end

Nodes::Or.class_eval do
  def evaluate
    left = lhs.evaluate
    return left if Eval.to_boolean(left)
    rhs.evaluate
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

STRING_NUMERIC_LITERAL_RE = %r{^
  \s*
  (?: (?<dec>
        (?<sign>[+-])?
        (?:(?<int>\d+)(?:\.(?<frac>\d+)?)? | \.(?<frac>\d+))
        (?<exp>e[+-]?\d+)? ) |
      0x(?<hex>[\da-f]+) )?
  \s*
$}xi

def to_number(obj)
  case obj
  when nil
    0.0/0.0 # NaN
  when true
    1.0
  when RazorPit::NULL, false
    0.0
  when Float
    obj
  when String
    m = STRING_NUMERIC_LITERAL_RE.match(obj)
    if m
      if m['dec']
        "#{m['sign']}#{m['int']||0}.#{m['frac']||0}#{m['exp']}".to_f
      elsif m['hex']
        m['hex'].to_i(16).to_f
      else
        0.0
      end
    else
      0.0/0.0 # NaN
    end
  else
    0.0/0.0 # NaN
  end
end

def to_int32(obj)
  obj = to_number(obj)
  return 0.0 if obj.infinite? || obj.nan? || obj.zero?
  abs = obj.abs
  (obj / abs) * abs.floor
end

def to_string(obj)
  case obj
  when Float
    if obj.finite?
      as_int = obj.to_i
      if as_int == obj
        as_int.to_s
      else
        obj.to_s
      end
    else
      obj.to_s
    end
  else
    obj.to_s
  end
end

def to_boolean(obj)
  case obj
  when String
    !obj.empty?
  when Float
    !(obj.zero? or obj.nan?)
  when nil, false, RazorPit::NULL
    false
  else
    true
  end
end

def evaluate(ast)
  ast.evaluate
end

end
end
