require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'

describe RazorPit::Parser do
  const_set :N, RazorPit::Nodes

  it "parses an empty program" do
    ast = RazorPit::Parser.parse("")
    ast.should == N::Program[]
  end

  it "parses an expression" do
    ast = RazorPit::Parser.parse_expression("1")
    ast.should == N::Number[1]
  end

  it "parses an addition expression" do
    ast = RazorPit::Parser.parse_expression("1 + 2")
    ast.should == N::Add[N::Number[1], N::Number[2]]
  end

  it "parses unary plus" do
    ast = RazorPit::Parser.parse_expression("+2")
    ast.should == N::UnaryPlus[N::Number[2]]
  end

  it "parses boolean literals" do
    ast = RazorPit::Parser.parse_expression("true")
    ast.should == N::Boolean[true]
    ast = RazorPit::Parser.parse_expression("false")
    ast.should == N::Boolean[false]
  end

  it "parses nulls" do
    ast = RazorPit::Parser.parse_expression("null")
    ast.should == N::NULL
  end

  it "parses subtraction" do
    ast = RazorPit::Parser.parse_expression("2 - 1")
    ast.should == N::Subtract[N::Number[2], N::Number[1]]
  end

  it "parses unary minus" do
    ast = RazorPit::Parser.parse_expression("-1")
    ast.should == N::UnaryMinus[N::Number[1]]
  end

  it "handles precedence correctly for unary versus binary +-" do
    ast = RazorPit::Parser.parse_expression("-1+-+2")
    ast.should == N::Add[N::UnaryMinus[N::Number[1]], N::UnaryMinus[N::UnaryPlus[N::Number[2]]]]
  end

  it "parses parenthesised subexpressions" do
    ast = RazorPit::Parser.parse_expression("(1+2)+3")
    ast.should == N::Add[N::Add[N::Number[1], N::Number[2]], N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1+(2+3)")
    ast.should == N::Add[N::Number[1], N::Add[N::Number[2], N::Number[3]]]
  end

  it "parses multiplication" do
    ast = RazorPit::Parser.parse_expression("1 * 2")
    ast.should == N::Multiply[N::Number[1], N::Number[2]]
  end

  it "parses division" do
    ast = RazorPit::Parser.parse_expression("1 / 2")
    ast.should == N::Divide[N::Number[1], N::Number[2]]
  end

  it "parses the modulus operator" do
    ast = RazorPit::Parser.parse_expression("1 % 2")
    ast.should == N::Modulus[N::Number[1], N::Number[2]]
  end

  it "should parse typeof" do
    ast = RazorPit::Parser.parse_expression("typeof 3")
    ast.should == N::TypeOf[N::Number[3]]
  end

  it "should parse void" do
    ast = RazorPit::Parser.parse_expression("void 0")
    ast.should == N::Void[N::Number[0]]
  end

  it "should parse logical negation" do
    ast = RazorPit::Parser.parse_expression("!true")
    ast.should == N::Not[N::Boolean[true]]
  end

  it "should parse string literals" do
    ast = RazorPit::Parser.parse_expression("'foobar'")
    ast.should == N::String["foobar"]
  end

  it "should parse regular expression literals" do
    ast = RazorPit::Parser.parse_expression("/foobar/")
    ast.should == N::RegEx["foobar"]
  end

  it "should parse logical and" do
    ast = RazorPit::Parser.parse_expression("true && false")
    ast.should == N::And[N::Boolean[true], N::Boolean[false]]
  end

  it "should parse logical or" do
    ast = RazorPit::Parser.parse_expression("true || false")
    ast.should == N::Or[N::Boolean[true], N::Boolean[false]]
  end

  it "should parse bitwise and" do
    ast = RazorPit::Parser.parse_expression("1 & 2")
    ast.should == N::BitwiseAnd[N::Number[1], N::Number[2]]
  end

  it "should parse bitwise or" do
    ast = RazorPit::Parser.parse_expression("1 | 2")
    ast.should == N::BitwiseOr[N::Number[1], N::Number[2]]
  end

  it "should parse bitwise xor" do
    ast = RazorPit::Parser.parse_expression("1 ^ 2")
    ast.should == N::BitwiseXOr[N::Number[1], N::Number[2]]
  end

  it "should parse bitwise not" do
    ast = RazorPit::Parser.parse_expression("~1")
    ast.should == N::BitwiseNot[N::Number[1]]
  end

  it "should parse equal" do
    ast = RazorPit::Parser.parse_expression("1 == 2")
    ast.should == N::Equal[N::Number[1], N::Number[2]]
  end

  it "should parse not equal" do
    ast = RazorPit::Parser.parse_expression("1 != 2")
    ast.should == N::NotEqual[N::Number[1], N::Number[2]]
  end

  it "should parse strictly equal" do
    ast = RazorPit::Parser.parse_expression("1 === 2")
    ast.should == N::StrictlyEqual[N::Number[1], N::Number[2]]
  end

  it "should parse strictly not equal" do
    ast = RazorPit::Parser.parse_expression("1 !== 2")
    ast.should == N::StrictlyNotEqual[N::Number[1], N::Number[2]]
  end

  def self.it_gives_higher_infix_precedence_to(op_a, op_b)
    it "gives #{op_a} precedence over #{op_b}" do
      ast_a = RazorPit::Parser.parse_expression("1 #{op_a} 2 #{op_b} 3")
      ast_a.lhs.lhs.should == N::Number[1]
      ast_a.lhs.rhs.should == N::Number[2]
      ast_a.rhs.should == N::Number[3]

      ast_b = RazorPit::Parser.parse_expression("1 #{op_b} 2 #{op_a} 3")
      ast_b.lhs.should == N::Number[1]
      ast_b.rhs.lhs.should == N::Number[2]
      ast_b.rhs.rhs.should == N::Number[3]
    end
  end

  def self.it_gives_equal_infix_precedence_to(op_a, op_b)
    it "gives equal precedence to #{op_a} and #{op_b}" do
      ast_a = RazorPit::Parser.parse_expression("1 #{op_a} 2 #{op_b} 3")
      ast_a.lhs.lhs.should == N::Number[1]
      ast_a.lhs.rhs.should == N::Number[2]
      ast_a.rhs.should == N::Number[3]

      ast_b = RazorPit::Parser.parse_expression("1 #{op_b} 2 #{op_a} 3")
      ast_b.lhs.lhs.should == N::Number[1]
      ast_b.lhs.rhs.should == N::Number[2]
      ast_b.rhs.should == N::Number[3]
    end
  end

  it_gives_equal_infix_precedence_to "+", "-"
  it_gives_equal_infix_precedence_to "*", "/"
  it_gives_equal_infix_precedence_to "*", "%"
  it_gives_equal_infix_precedence_to "==", "!="
  it_gives_equal_infix_precedence_to "==", "==="
  it_gives_equal_infix_precedence_to "==", "!=="

  it_gives_higher_infix_precedence_to "*", "+"
  it_gives_higher_infix_precedence_to "+", "=="
  it_gives_higher_infix_precedence_to "==", "&"
  it_gives_higher_infix_precedence_to "&", "^"
  it_gives_higher_infix_precedence_to "^", "|"
  it_gives_higher_infix_precedence_to "|", "&&"
  it_gives_higher_infix_precedence_to "&&", "||"
end
