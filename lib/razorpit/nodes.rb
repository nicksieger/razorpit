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

class StatementListNode < Node
  attr_reader :statements

  def initialize(*statements)
    @statements = statements
  end

  def ==(other)
    self.class == other.class && self.statements == other.statements
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

  class RegExp < Node
    attr_reader :source, :flags

    def initialize((source, flags))
      @source = source
      @flags = flags
    end

    def ==(other)
      self.class == other.class &&
      self.source == other.source &&
      self.flags == other.flags
    end
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

  class Program < StatementListNode
  end

  class Block < StatementListNode
  end

  class Return < UnaryOpNode
    def initialize(expr=nil)
      super(expr)
    end
  end

  class Continue < Node
    def ==(other)
      self.class == other.class
    end
  end

  class Break < Node
    def ==(other)
      self.class == other.class
    end
  end

  class Function < Node
    attr_reader :name
    attr_reader :args
    attr_reader :body

    def initialize(name, args, *body)
      @name = name && name.to_sym
      @args = args.map { |a| a.to_sym }
      @body = Block.new(*body)
    end

    def ==(other)
      self.class == other.class &&
      self.name == other.name &&
      self.args == other.args &&
      self.body == other.body
    end
  end

  class FunctionDeclaration < Function
  end

  class EmptyStatement < Node
  end

  class If < Node
    attr_reader :predicate, :then_clause, :else_clause

    def initialize(predicate, then_clause, else_clause=nil)
      @predicate = predicate
      @then_clause = then_clause
      @else_clause = else_clause
    end

    def ==(other)
      self.class == other.class &&
      self.predicate == other.predicate &&
      self.then_clause == other.then_clause &&
      self.else_clause == other.else_clause
    end
  end

  class DoWhile < Node
    attr_reader :body
    attr_reader :predicate

    def initialize(body, predicate)
      @body = body
      @predicate = predicate
    end

    def ==(other)
      self.class == other.class &&
      self.body == other.body &&
      self.predicate == other.predicate
    end
  end

  class While < Node
    attr_reader :predicate
    attr_reader :body

    def initialize(predicate, body)
      @predicate = predicate
      @body = body
    end

    def ==(other)
      self.class == other.class &&
      self.predicate == other.predicate &&
      self.body == other.body
    end
  end

  class For < Node
    attr_reader :init
    attr_reader :predicate
    attr_reader :incr
    attr_reader :body

    def initialize(init, predicate, incr, body)
      @init = init
      @predicate = predicate
      @incr = incr
      @body = body
    end

    def ==(other)
      self.class == other.class &&
      self.init == other.init &&
      self.predicate == other.predicate &&
      self.incr == other.incr &&
      self.body == other.body
    end
  end

  class VariableStatement < Node
    attr_reader :decls

    def initialize(decls)
      @decls = {}
      decls.each do |name, init|
        @decls[name.to_sym] = init
      end
    end

    def ==(other)
      self.class == other.class && self.decls == other.decls
    end
  end

  class PropertyAccess < BinaryOpNode
  end

  class FunctionCall < Node
    attr_reader :func
    attr_reader :args

    def initialize(func, *args)
      @func = func
      @args = args
    end

    def ==(other)
      self.class == other.class &&
      self.func == other.func &&
      self.args == other.args
    end
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

  class Delete < UnaryOpNode
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
