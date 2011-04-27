require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'

N = RazorPit::Nodes

describe RazorPit::Parser do
  it "parses an empty program" do
    ast = RazorPit::Parser.parse("")
    ast.should == N::Program[]
  end

  it "parses a numeric literal" do
    ast = RazorPit::Parser.parse_expression("1")
    ast.should == N::Number[1]
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

  it "handles precedence correctly for unary versus binary +-" do
    ast = RazorPit::Parser.parse_expression("-1+-+2")
    ast.should == N::Add[N::UnaryMinus[N::Number[1]],
                         N::UnaryMinus[N::UnaryPlus[N::Number[2]]]]
  end

  it "parses parenthesised subexpressions" do
    ast = RazorPit::Parser.parse_expression("(1+2)+3")
    ast.should == N::Add[N::Add[N::Number[1], N::Number[2]], N::Number[3]]
    ast = RazorPit::Parser.parse_expression("1+(2+3)")
    ast.should == N::Add[N::Number[1], N::Add[N::Number[2], N::Number[3]]]
  end

  it "should parse string literals" do
    ast = RazorPit::Parser.parse_expression("'foobar'")
    ast.should == N::String["foobar"]
  end

  it "should parse regular expression literals" do
    ast = RazorPit::Parser.parse_expression("/foobar/")
    ast.should == N::RegEx["foobar"]
  end

  it "should parse the ternary conditional operator" do
    ast = RazorPit::Parser.parse_expression("1 ? 2 : 3")
    ast.should == N::Condition[N::Number[1], N::Number[2], N::Number[3]]
  end

  def self.it_parses_prefix(op, node_class)
    it "parses prefix #{op}" do
      ast = RazorPit::Parser.parse_expression("#{op} 1")
      ast.should == node_class[N::Number[1]]
    end
  end

  it_parses_prefix "!", N::Not
  it_parses_prefix "~", N::BitwiseNot
  it_parses_prefix "void", N::Void
  it_parses_prefix "typeof", N::TypeOf
  it_parses_prefix "+", N::UnaryPlus
  it_parses_prefix "-", N::UnaryMinus

  def self.it_parses_infix(op, node_class)
    it "parses infix #{op}" do
      ast = RazorPit::Parser.parse_expression("1 #{op} 2")
      ast.should == node_class[N::Number[1], N::Number[2]]
    end
  end

  it_parses_infix "+", N::Add
  it_parses_infix "-", N::Subtract
  it_parses_infix "*", N::Multiply
  it_parses_infix "/", N::Divide
  it_parses_infix "%", N::Modulus

  it_parses_infix "==", N::Equal
  it_parses_infix "!=", N::NotEqual
  it_parses_infix "===", N::StrictlyEqual
  it_parses_infix "!==", N::StrictlyNotEqual

  it_parses_infix "<<", N::LeftShift
  it_parses_infix ">>", N::SignedRightShift
  it_parses_infix ">>>", N::UnsignedRightShift

  it_parses_infix "&&", N::And
  it_parses_infix "||", N::Or
  it_parses_infix "&", N::BitwiseAnd
  it_parses_infix "^", N::BitwiseXOr
  it_parses_infix "|", N::BitwiseOr

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

  it_gives_equal_infix_precedence_to "*", "/"
  it_gives_equal_infix_precedence_to "*", "%"
  it_gives_equal_infix_precedence_to "+", "-"
  it_gives_equal_infix_precedence_to "<<", ">>"
  it_gives_equal_infix_precedence_to "<<", ">>>"
  it_gives_equal_infix_precedence_to "==", "!="
  it_gives_equal_infix_precedence_to "==", "==="
  it_gives_equal_infix_precedence_to "==", "!=="

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

  it_gives_higher_infix_precedence_to "*", "+"
  it_gives_higher_infix_precedence_to "+", ">>"
  it_gives_higher_infix_precedence_to ">>", "=="
  it_gives_higher_infix_precedence_to "==", "&"
  it_gives_higher_infix_precedence_to "&", "^"
  it_gives_higher_infix_precedence_to "^", "|"
  it_gives_higher_infix_precedence_to "|", "&&"
  it_gives_higher_infix_precedence_to "&&", "||"

  it "gives infix precedence to || over ?:" do
    ast = RazorPit::Parser.parse_expression("1 || 2 ? 3 || 4 : 5 || 6")
    ast.should == N::Condition[N::Or[N::Number[1], N::Number[2]],
                               N::Or[N::Number[3], N::Number[4]],
                               N::Or[N::Number[5], N::Number[6]]]
  end
end
