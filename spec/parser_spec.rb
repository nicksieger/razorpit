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

  it "should give bitwise and lower precedence than addition" do
    ast = RazorPit::Parser.parse_expression("1 & 2 + 3")
    ast.should == N::BitwiseAnd[N::Number[1],
                                N::Add[N::Number[2], N::Number[3]]]
    ast = RazorPit::Parser.parse_expression("1 + 2 & 3")
    ast.should == N::BitwiseAnd[N::Add[N::Number[1], N::Number[2]],
                                N::Number[3]]
  end

  it "should give logical or lower precedence than logical and" do
    ast = RazorPit::Parser.parse_expression("1 || 2 && 3")
    ast.should == N::Or[N::Number[1],
                        N::And[N::Number[2], N::Number[3]]]
    ast = RazorPit::Parser.parse_expression("1 && 2 || 3")
    ast.should == N::Or[N::And[N::Number[1], N::Number[2]],
                        N::Number[3]]
  end

  it "should give bitwise or higher precedence than logical and" do
    ast = RazorPit::Parser.parse_expression("1 | 2 && 3")
    ast.should == N::And[N::BitwiseOr[N::Number[1], N::Number[2]],
                         N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1 && 2 | 3")
    ast.should == N::And[N::Number[1],
                         N::BitwiseOr[N::Number[2], N::Number[3]]]
  end

  it "should give bitwise xor higher precedence than bitwise or" do
    ast = RazorPit::Parser.parse_expression("1 ^ 2 | 3")
    ast.should == N::BitwiseOr[N::BitwiseXOr[N::Number[1], N::Number[2]],
                               N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1 | 2 ^ 3")
    ast.should == N::BitwiseOr[N::Number[1],
                               N::BitwiseXOr[N::Number[2], N::Number[3]]]
  end

  it "should give bitwise and higher precedence than bitwise xor" do
    ast = RazorPit::Parser.parse_expression("1 & 2 ^ 3")
    ast.should == N::BitwiseXOr[N::BitwiseAnd[N::Number[1], N::Number[2]],
                                N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1 ^ 2 & 3")
    ast.should == N::BitwiseXOr[N::Number[1],
                                N::BitwiseAnd[N::Number[2], N::Number[3]]]
  end
end
