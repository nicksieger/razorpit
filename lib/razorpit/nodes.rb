module RazorPit

class Node
  class << self
    alias_method :[], :new
  end

  def ==(other)
    false
  end
end

module Nodes
  class Number < Node
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def ==(other)
      self.class == other.class && self.value == other.value
    end
  end

  class Program < Node
    def ==(other)
      self.class == other.class
    end
  end

  class Add < Node
    attr_reader :a, :b

    def initialize(a, b)
      @a = a
      @b = b
    end

    def ==(other)
      self.class == other.class && self.a == other.a && self.b == other.b
    end
  end
end

end
