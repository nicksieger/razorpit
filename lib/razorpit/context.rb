require 'razorpit/parser'
require 'razorpit/eval'

module RazorPit

class Context
  module Helpers
    extend self
    def to_ruby(value)
      case value
      when RazorPit::NULL
        nil
      else
        value
      end
    end
  end

  def initialize
    @env = RazorPit::Environment.new
  end

  def eval(string)
    ast = Parser.parse_expression(string)
    Helpers.to_ruby(Eval.evaluate(ast, @env))
  end
end

end
