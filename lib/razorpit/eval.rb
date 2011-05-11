require 'razorpit/nodes'

module RazorPit

NULL = Object.new
class << NULL
  def to_s
    RazorPit::NULL
  end
  alias_method :inspect, :to_s
end

Node.class_eval do
  def evaluate
    raise NotImplementedError, "#{self.class}#evaluate not implemented"
  end
end

LiteralNode.class_eval do
  def evaluate
    value
  end
end

Nodes::Identifier.class_eval do
  def evaluate
    nil
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

Nodes::BitwiseNot.class_eval do
  def evaluate
    (~Eval.to_int32(expr.evaluate).to_i).to_f
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

Nodes::BitwiseAnd.class_eval do
  def evaluate
    left = Eval.to_int32(lhs.evaluate).to_i
    right = Eval.to_int32(rhs.evaluate).to_i
    (left & right).to_f
  end
end

Nodes::BitwiseXOr.class_eval do
  def evaluate
    left = Eval.to_int32(lhs.evaluate).to_i
    right = Eval.to_int32(rhs.evaluate).to_i
    (left ^ right).to_f
  end
end

Nodes::BitwiseOr.class_eval do
  def evaluate
    left = Eval.to_int32(lhs.evaluate).to_i
    right = Eval.to_int32(rhs.evaluate).to_i
    (left | right).to_f
  end
end

Nodes::LeftShift.class_eval do
  def evaluate
    value = Eval.to_int32(lhs.evaluate).to_i
    shift = Eval.to_uint32(rhs.evaluate).to_i & 0x1f
    value = ((value << shift) & 0xffffffff).to_f
    value -= (1 << 32) if value >= (1 << 31)
    value
  end
end

Nodes::SignedRightShift.class_eval do
  def evaluate
    value = Eval.to_int32(lhs.evaluate).to_i
    shift = Eval.to_uint32(rhs.evaluate).to_i & 0x1f
    (value >> shift).to_f
  end
end

Nodes::UnsignedRightShift.class_eval do
  def evaluate
    value = Eval.to_uint32(lhs.evaluate).to_i
    shift = Eval.to_uint32(rhs.evaluate).to_i & 0x1f
    (value >> shift).to_f
  end
end

Nodes::Condition.class_eval do
  def evaluate
    if Eval.to_boolean(predicate.evaluate)
      then_expr.evaluate
    else
      else_expr.evaluate
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

Nodes::Equal.class_eval do
  def evaluate
    Eval.abstractly_equal?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::NotEqual.class_eval do
  def evaluate
    not Eval.abstractly_equal?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::StrictlyEqual.class_eval do
  def evaluate
    Eval.strictly_equal?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::StrictlyNotEqual.class_eval do
  def evaluate
    not Eval.strictly_equal?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::LessThan.class_eval do
  def evaluate
    Eval.less_than?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::GreaterThan.class_eval do
  def evaluate
    Eval.greater_than?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::LessThanOrEqual.class_eval do
  def evaluate
    Eval.less_than_or_equal?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::GreaterThanOrEqual.class_eval do
  def evaluate
    Eval.greater_than_or_equal?(lhs.evaluate, rhs.evaluate)
  end
end

Nodes::Sequence.class_eval do
  def evaluate
    lhs.evaluate
    rhs.evaluate
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

def to_uint32(obj)
  float = to_number(obj)
  return 0.0 if float.infinite? || float.nan? || float.zero?
  abs = float.abs
  value = (float / abs).to_i * abs.floor
  value &= 0xffffffff
  value.to_f
end

def to_int32(obj)
  value = to_uint32(obj)
  value -= (1 << 32) if value >= (1 << 31)
  value
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

def strictly_equal?(a, b)
  return false if a.class != b.class
  case a
  when nil, NULL
    true
  when Float
    if a.nan? or b.nan?
      false
    elsif a.zero? and b.zero?
      true
    else
      a == b
    end
  else
    a == b
  end
end

def less_than?(a, b)
  if a.class == String and b.class == String
    a < b
  else
    a = to_number(a)
    b = to_number(b)
    to_number(a) < to_number(b)
  end
end

def greater_than?(a, b)
  less_than?(b, a)
end

def less_than_or_equal?(a, b)
  not greater_than?(a, b)
end

def greater_than_or_equal?(a, b)
  not less_than?(a, b)
end

def abstractly_equal?(a, b)
  strictly_equal?(a, b)
end

def evaluate(ast)
  ast.evaluate
end

end
end
