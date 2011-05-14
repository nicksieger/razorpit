require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'

N = RazorPit::Nodes

describe RazorPit::Parser do
  it "parses an empty program" do
    ast = RazorPit::Parser.parse("")
    ast.should == N::Program[]
  end

  it "raises ParseError on invalid syntax" do
    lambda {
      RazorPit::Parser.parse("1 2")
    }.should raise_error(RazorPit::ParseError)
  end

  it "parses a return statement with value" do
    ast = RazorPit::Parser.parse("return 3")
    ast.should == N::Program[N::Return[N::Number[3]]]
  end

  it "assumes semicolon before } and EOF" do
    ast = RazorPit::Parser.parse("1; 2")
    ast.should == N::Program[N::Number[1], N::Number[2]]
    ast = RazorPit::Parser.parse("{1; 2}")
    ast.should == N::Program[N::Block[N::Number[1], N::Number[2]]]
  end

  it "assumes semicolon at significant line breaks" do
    ast = RazorPit::Parser.parse("1\n2")
    ast.should == N::Program[N::Number[1], N::Number[2]]
  end

  it "does not assume semicolons at non-signifiant line breaks" do
    ast = RazorPit::Parser.parse("1\n+ 2")
    ast.should == N::Program[N::Add[N::Number[1], N::Number[2]]]
  end

  it "parses a program with an empty statement" do
    ast = RazorPit::Parser.parse(";")
    ast.should == N::Program[]
  end

  it "parses a program with a simple expression statement" do
    ast = RazorPit::Parser.parse("void 0; void 1;")
    ast.should == N::Program[N::Void[N::Number[0]],
                             N::Void[N::Number[1]]]
  end

  it "parses a program with a block" do
    ast = RazorPit::Parser.parse <<-EOS
      {
        void 0;
        void 1;
      }
    EOS
    ast.should == N::Program[N::Block[N::Void[N::Number[0]],
                                      N::Void[N::Number[1]]]]
  end

  it "should parse slashes as regular expressions in prefix position" do
    ast = RazorPit::Parser.parse("/foo/i")
    ast.should == N::Program[N::RegExp[["foo", "i"]]]
  end

  it "should parse slashes as division in infix position" do
    ast = RazorPit::Parser.parse("a/foo/i")
    ast.should == N::Program[N::Divide[N::Divide[N::Identifier["a"],
                                                 N::Identifier["foo"]],
                                       N::Identifier["i"]]]
  end

  it "parses a variable statement" do
    ast = RazorPit::Parser.parse("var a=1, b;")
    ast.should == N::Program[N::VariableStatement["a" => N::Number[1],
                                                  "b" => nil]]
  end

  it "parses a function declaration" do
    ast = RazorPit::Parser.parse("function foo(a, b) { a + b; }")
    ast.should == N::Program[
                    N::FunctionDeclaration["foo", ["a", "b"],
                      N::Add[N::Identifier["a"], N::Identifier["b"]]]]
  end

  it "parses a named function expression" do
    ast = RazorPit::Parser.parse("(function foo(a, b) { a + b; })")
    ast.should == N::Program[
                    N::Function["foo", ["a", "b"],
                      N::Add[N::Identifier["a"], N::Identifier["b"]]]]
  end

  it "parses an anonymous function expression" do
    ast = RazorPit::Parser.parse("(function (a, b) { a + b; })")
    ast.should == N::Program[
                    N::Function[nil, ["a", "b"],
                      N::Add[N::Identifier["a"], N::Identifier["b"]]]]
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
    ast.should == N::RegExp[["foobar", ""]]
  end

  it "should parse the ternary conditional operator" do
    ast = RazorPit::Parser.parse_expression("1 ? 2 : 3")
    ast.should == N::Condition[N::Number[1], N::Number[2], N::Number[3]]
  end

  it "parses preincrement" do
    ast = RazorPit::Parser.parse_expression("++i")
    ast.should == N::PreIncrement[N::Identifier["i"]]
  end

  it "parses postincrement" do
    ast = RazorPit::Parser.parse_expression("i++")
    ast.should == N::PostIncrement[N::Identifier["i"]]
  end

  it "parses predecrement" do
    ast = RazorPit::Parser.parse_expression("--i")
    ast.should == N::PreDecrement[N::Identifier["i"]]
  end

  it "parses postdecrement" do
    ast = RazorPit::Parser.parse_expression("i--")
    ast.should == N::PostDecrement[N::Identifier["i"]]
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

  it_parses_infix ">", N::GreaterThan
  it_parses_infix "<", N::LessThan
  it_parses_infix ">=", N::GreaterThanOrEqual
  it_parses_infix "<=", N::LessThanOrEqual

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

  it_parses_infix "=", N::Assign
  it_parses_infix "+=", N::AddAssign
  it_parses_infix "-=", N::SubtractAssign
  it_parses_infix "*=", N::MultiplyAssign
  it_parses_infix "/=", N::DivideAssign
  it_parses_infix "%=", N::ModulusAssign
  it_parses_infix "<<=", N::LeftShiftAssign
  it_parses_infix ">>=", N::SignedRightShiftAssign
  it_parses_infix ">>>=", N::UnsignedRightShiftAssign
  it_parses_infix "&=", N::BitwiseAndAssign
  it_parses_infix "^=", N::BitwiseXOrAssign
  it_parses_infix "|=", N::BitwiseOrAssign

  it_parses_infix ",", N::Sequence

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
  it_gives_equal_infix_precedence_to ">", "<"
  it_gives_equal_infix_precedence_to ">", ">="
  it_gives_equal_infix_precedence_to ">", "<="
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
  it_gives_higher_infix_precedence_to ">>", ">"
  it_gives_higher_infix_precedence_to ">", "=="
  it_gives_higher_infix_precedence_to "==", "&"
  it_gives_higher_infix_precedence_to "&", "^"
  it_gives_higher_infix_precedence_to "^", "|"
  it_gives_higher_infix_precedence_to "|", "&&"
  it_gives_higher_infix_precedence_to "&&", "||"
  it_gives_higher_infix_precedence_to "||", ","

  it "gives infix precedence to || over ?:" do
    ast = RazorPit::Parser.parse_expression("1 || 2 ? 3 || 4 : 5 || 6")
    ast.should == N::Condition[N::Or[N::Number[1], N::Number[2]],
                               N::Or[N::Number[3], N::Number[4]],
                               N::Or[N::Number[5], N::Number[6]]]
  end

  it "parses ?: with right-to-left associativity" do
    ast = RazorPit::Parser.parse_expression("1 ? 2 : 3 ? 4 : 5")
    ast.should == N::Condition[N::Number[1], N::Number[2],
                               N::Condition[N::Number[3], N::Number[4],
                                            N::Number[5]]]
  end

  it "parses ?: with higher precedence than ," do
    ast = RazorPit::Parser.parse_expression("1 ? 2 : 3, 4")
    ast.should == N::Sequence[N::Condition[N::Number[1], N::Number[2],
                                           N::Number[3]],
                              N::Number[4]]
  end

  it "parses direct property access" do
    ast = RazorPit::Parser.parse_expression("foo.bar")
    ast.should == N::PropertyAccess[N::Identifier["foo"],
                                    N::String["bar"]]
  end

  it "parses subscripted property access" do
    ast = RazorPit::Parser.parse_expression("foo['bar']")
    ast.should == N::PropertyAccess[N::Identifier["foo"],
                                    N::String["bar"]]
  end

  it "parses dynamic property access" do
    ast = RazorPit::Parser.parse_expression("foo[bar]")
    ast.should == N::PropertyAccess[N::Identifier["foo"],
                                    N::Identifier["bar"]]
  end

  it "parses function calls with no arguments" do
    ast = RazorPit::Parser.parse_expression("foo()")
    ast.should == N::FunctionCall[N::Identifier["foo"]]
  end

  it "parses function calls with arguments" do
    ast = RazorPit::Parser.parse_expression("foo(1, 2)")
    ast.should == N::FunctionCall[N::Identifier["foo"],
                                  N::Number[1], N::Number[2]]
  end

  it "parses method calls" do
    ast = RazorPit::Parser.parse_expression("foo.bar(1, 2)")
    ast.should == N::FunctionCall[N::PropertyAccess[N::Identifier["foo"],
                                                    N::String["bar"]],
                                  N::Number[1], N::Number[2]]
  end

  it "parses delete" do
    ast = RazorPit::Parser.parse_expression("delete foo['bar']")
    ast.should == N::Delete[N::PropertyAccess[N::Identifier["foo"],
                                              N::String["bar"]]]
  end
end
