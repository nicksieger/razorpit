require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'

Module.new do

N = RazorPit::Nodes

describe RazorPit::Parser do
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

  it "should give addition and subtraction the same precedence" do
    ast = RazorPit::Parser.parse_expression("1 + 2 - 3")
    ast.should == N::Subtract[N::Add[N::Number[1], N::Number[2]],
                              N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1 - 2 + 3")
    ast.should == N::Add[N::Subtract[N::Number[1], N::Number[2]],
                         N::Number[3]]
  end

  it "should give multiplication higher precedence than addition" do
    ast = RazorPit::Parser.parse_expression("1 + 2 * 3")
    ast.should == N::Add[N::Number[1], N::Multiply[N::Number[2], N::Number[3]]]
  end

  it "should give multiplication and division the same precedence" do
    ast = RazorPit::Parser.parse_expression("1 * 2 / 3")
    ast.should == N::Divide[N::Multiply[N::Number[1], N::Number[2]],
                            N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1 / 2 * 3")
    ast.should == N::Multiply[N::Divide[N::Number[1], N::Number[2]],
                              N::Number[3]]
  end

  it "should give multiplication and modulus the same precedence" do
    ast = RazorPit::Parser.parse_expression("1 * 2 % 3")
    ast.should == N::Modulus[N::Multiply[N::Number[1], N::Number[2]],
                             N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1 % 2 * 3")
    ast.should == N::Multiply[N::Modulus[N::Number[1], N::Number[2]],
                              N::Number[3]]
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
end

end
