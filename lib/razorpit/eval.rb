require 'razorpit/nodes'

module RazorPit

NULL = Object.new
class << NULL
  def to_s
    RazorPit::NULL
  end
  alias_method :inspect, :to_s
end

class Function
  attr_reader :name

  def initialize(name, args, env, body)
    @name = name
    @args = args
    @env = env
    @body = body
  end

  def call(args)
    env = Environment.new(@env)
    @args.zip(args) do |name, value|
      env.declare(name) { value }
    end
    catch(:razorpit_return) do
      @body.evaluate(env)
      nil
    end
  end
end

class Environment
  def initialize(parent=nil)
    @variables = {}
    @parent = parent
  end

  def declare(name)
    @variables[name] = yield
  end

  def [](name)
    if @parent and !@variables.has_key?(name)
      @parent[name]
    else
      @variables[name]
    end
  end

  def []=(name, value)
    if @parent and !@variables.has_key?(name)
      @parent[name] = value
    else
      @variables[name] = value 
    end
  end

  def delete(name)
    if @parent and !@variables.has_key?(name)
      @parent.delete name
    else
      @variables.delete name
      true
    end
  end
end

Node.class_eval do
  def evaluate(env)
    raise NotImplementedError, "#{self.class}#evaluate not implemented"
  end

  def delete(env)
    raise NotImplementedError, "#{self.class}#delete is not implemented"
  end

  def update(env)
    raise NotImplementedError, "#{self.class}#update not implemented"
  end

  def call(env, args)
    func = evaluate(env)
    func.call(args)
  end
end

LiteralNode.class_eval do
  def evaluate(env)
    value
  end
end

StatementListNode.class_eval do
  def evaluate(env)
    result = nil
    statements.each do |statement|
      result = statement.evaluate(env)
    end
    result
  end
end

Nodes::Function.class_eval do
  def evaluate(env)
    RazorPit::Function.new(name, args, env, body)
  end
end

Nodes::FunctionDeclaration.class_eval do
  def evaluate(env)
    f = super(env)
    env[f.name] = f
  end
end

Nodes::FunctionCall.class_eval do
  def evaluate(env)
    values = args.map { |a| a.evaluate(env) }
    func.call(env, values)
  end
end

Nodes::Return.class_eval do
  def evaluate(env)
    throw :razorpit_return, expr.evaluate(env)
  end
end

Nodes::Identifier.class_eval do
  def evaluate(env)
    env[name]
  end

  def delete(env)
    env.delete name
  end

  def update(env)
    env[name] = yield env[name]
  end
end

Nodes::Block.class_eval do
  def evaluate(env)
    super(Environment.new(env))
  end
end

Nodes::VariableStatement.class_eval do
  def evaluate(env)
    decls.each do |name, init|
      env.declare(name) do
        if init
          init.evaluate(env)
        else
          nil
        end
      end
    end
  end
end

Nodes::Assign.class_eval do
  def evaluate(env)
    lhs.update(env) { rhs.evaluate(env) }
  end
end

Nodes::Delete.class_eval do
  def evaluate(env)
    expr.delete(env)
  end
end

Nodes::AddAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.add(value, rhs.evaluate(env)) }
  end
end

Nodes::SubtractAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.subtract(value, rhs.evaluate(env)) }
  end
end

Nodes::MultiplyAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.multiply(value, rhs.evaluate(env)) }
  end
end

Nodes::DivideAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.divide(value, rhs.evaluate(env)) }
  end
end

Nodes::ModulusAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.modulus(value, rhs.evaluate(env)) }
  end
end

Nodes::LeftShiftAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.left_shift(value, rhs.evaluate(env)) }
  end
end

Nodes::SignedRightShiftAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value|
      Eval.signed_right_shift(value, rhs.evaluate(env))
    }
  end
end

Nodes::UnsignedRightShiftAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value|
      Eval.unsigned_right_shift(value, rhs.evaluate(env))
    }
  end
end

Nodes::BitwiseAndAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.bitwise_and(value, rhs.evaluate(env)) }
  end
end

Nodes::BitwiseXOrAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.bitwise_xor(value, rhs.evaluate(env)) }
  end
end

Nodes::BitwiseOrAssign.class_eval do
  def evaluate(env)
    lhs.update(env) { |value| Eval.bitwise_or(value, rhs.evaluate(env)) }
  end
end

Nodes::PreIncrement.class_eval do
  def evaluate(env)
    expr.update(env) { |value| Eval.add(value, 1.0) }
  end
end

Nodes::PostIncrement.class_eval do
  def evaluate(env)
    old_value = nil
    expr.update(env) { |value|
      old_value = Eval.to_number(value)
      Eval.add(old_value, 1.0)
    }
    old_value
  end
end

Nodes::PreDecrement.class_eval do
  def evaluate(env)
    expr.update(env) { |value| Eval.subtract(value, 1.0) }
  end
end

Nodes::PostDecrement.class_eval do
  def evaluate(env)
    old_value = nil
    expr.update(env) { |value|
      old_value = Eval.to_number(value)
      Eval.subtract(old_value, 1.0)
    }
    old_value
  end
end

Nodes::UnaryPlus.class_eval do
  def evaluate(env)
    expr.evaluate(env)
  end
end

Nodes::UnaryMinus.class_eval do
  def evaluate(env)
    -expr.evaluate(env)
  end
end

Nodes::BitwiseNot.class_eval do
  def evaluate(env)
    (~Eval.to_int32(expr.evaluate(env)).to_i).to_f
  end
end

Nodes::Add.class_eval do
  def evaluate(env)
    Eval.add(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::Subtract.class_eval do
  def evaluate(env)
    Eval.subtract(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::Multiply.class_eval do
  def evaluate(env)
    Eval.multiply(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::Divide.class_eval do
  def evaluate(env)
    Eval.divide(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::Modulus.class_eval do
  def evaluate(env)
    Eval.modulus(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::TypeOf.class_eval do
  def evaluate(env)
    result = expr.evaluate(env)
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
  def evaluate(env)
    result = expr.evaluate(env)
    !Eval.to_boolean(result)
  end
end

Nodes::And.class_eval do
  def evaluate(env)
    left = lhs.evaluate(env)
    return left unless Eval.to_boolean(left)
    rhs.evaluate(env)
  end
end

Nodes::Or.class_eval do
  def evaluate(env)
    left = lhs.evaluate(env)
    return left if Eval.to_boolean(left)
    rhs.evaluate(env)
  end
end

Nodes::BitwiseAnd.class_eval do
  def evaluate(env)
    Eval.bitwise_and(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::BitwiseXOr.class_eval do
  def evaluate(env)
    Eval.bitwise_xor(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::BitwiseOr.class_eval do
  def evaluate(env)
    Eval.bitwise_or(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::LeftShift.class_eval do
  def evaluate(env)
    Eval.left_shift(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::SignedRightShift.class_eval do
  def evaluate(env)
    Eval.signed_right_shift(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::UnsignedRightShift.class_eval do
  def evaluate(env)
    Eval.unsigned_right_shift(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::Condition.class_eval do
  def evaluate(env)
    if Eval.to_boolean(predicate.evaluate(env))
      then_expr.evaluate(env)
    else
      else_expr.evaluate(env)
    end
  end
end

Nodes::Void.class_eval do
  def evaluate(env)
    nil
  end
end

class << Nodes::NULL
  def evaluate(env)
    RazorPit::NULL
  end
end

Nodes::Equal.class_eval do
  def evaluate(env)
    Eval.abstractly_equal?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::NotEqual.class_eval do
  def evaluate(env)
    not Eval.abstractly_equal?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::StrictlyEqual.class_eval do
  def evaluate(env)
    Eval.strictly_equal?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::StrictlyNotEqual.class_eval do
  def evaluate(env)
    not Eval.strictly_equal?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::LessThan.class_eval do
  def evaluate(env)
    Eval.less_than?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::GreaterThan.class_eval do
  def evaluate(env)
    Eval.greater_than?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::LessThanOrEqual.class_eval do
  def evaluate(env)
    Eval.less_than_or_equal?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::GreaterThanOrEqual.class_eval do
  def evaluate(env)
    Eval.greater_than_or_equal?(lhs.evaluate(env), rhs.evaluate(env))
  end
end

Nodes::Sequence.class_eval do
  def evaluate(env)
    lhs.evaluate(env)
    rhs.evaluate(env)
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

def add(a, b)
  if String === a or String === b
    "#{to_string(a)}#{to_string(b)}"
  else
    to_number(a) + to_number(b)
  end
end

def subtract(a, b)
  to_number(a) - to_number(b)
end

def multiply(a, b)
  to_number(a) * to_number(b)
end

def divide(a, b)
  to_number(a) / to_number(b)
end

def modulus(a, b)
  to_number(a) % to_number(b)
end

def left_shift(a, b)
  value = to_int32(a).to_i
  shift = to_uint32(b).to_i & 0x1f
  value = ((value << shift) & 0xffffffff).to_f
  value -= (1 << 32) if value >= (1 << 31)
  value
end

def signed_right_shift(a, b)
  value = to_int32(a).to_i
  shift = to_uint32(b).to_i & 0x1f
  (value >> shift).to_f
end

def unsigned_right_shift(a, b)
  value = to_uint32(a).to_i
  shift = to_uint32(b).to_i & 0x1f
  (value >> shift).to_f
end

def bitwise_and(a, b)
  left = to_int32(a).to_i
  right = to_int32(b).to_i
  (left & right).to_f
end

def bitwise_xor(a, b)
  left = to_int32(a).to_i
  right = to_int32(b).to_i
  (left ^ right).to_f
end

def bitwise_or(a, b)
  left = to_int32(a).to_i
  right = to_int32(b).to_i
  (left | right).to_f
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

def evaluate(ast, env)
  ast.evaluate(env)
end

end
end
