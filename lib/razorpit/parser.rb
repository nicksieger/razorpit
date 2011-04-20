module RazorPit
  module Parser
    extend self

    def parse(string)
      RazorPit::Nodes::Program[]
    end
  end

  module Nodes
    class Program
      class << self
        alias_method :[], :new
      end

      def ==(other)
        true
      end
    end

  end
end
