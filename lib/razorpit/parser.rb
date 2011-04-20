require 'razorpit/tokenizer'
require 'razorpit/nodes'

module RazorPit

module Parser
  extend self

  def parse(string)
    Nodes::Program[]
  end

  def parse_expression(string)
    Tokenizer.tokenize(string) do |token|
      case token
      when Tokens::NUMBER
        return Nodes::Number[token.value]
      end
    end
  end
end

end
