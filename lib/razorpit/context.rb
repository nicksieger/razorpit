require 'razorpit/parser'
require 'razorpit/eval'

module RazorPit

class Context
  def eval(string)
    ast = Parser.parse_expression(string)
    ast.evaluate
  end
end

end
