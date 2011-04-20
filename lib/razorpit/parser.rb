require 'razorpit/lexer'
require 'razorpit/nodes'

module RazorPit

module Parser
  extend self

  def parse(string)
    Nodes::Program[]
  end

  def parse_expression(string)
    tokens = Lexer.scan(string)

    token = tokens.next
    case token
    when Tokens::NUMBER
      Nodes::Number[token.value]
    end
  end
end

end
