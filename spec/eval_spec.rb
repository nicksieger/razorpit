require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'
require 'razorpit/eval'

describe "#{RazorPit::Eval}.evaluate" do
  def evaluate(string)
    ast = RazorPit::Parser.parse_expression(string)
    RazorPit::Eval.evaluate(ast)
  end

  it "can evaluate a trivial expression" do
    evaluate("1").should == 1.0
  end

  it "can evaluate an unary plus" do
    evaluate("+8").should == 8
  end

  it "can do trivial arithmetic" do
    evaluate("1 + 2").should == 3.0
  end

  it "can evaluate true and false" do
    evaluate("true").should == true
    evaluate("false").should == false
  end

  it "can evaluate null" do
    evaluate("null").should == RazorPit::NULL
  end

  it "can do subtraction" do
    evaluate("2 - 1").should == 1.0
  end

  it "understands unary minus" do
    evaluate("-1").should == -1.0
  end

  it "can do multiplication" do
    evaluate("2 * 3").should == 6.0
  end

  it "can do division" do
    evaluate("1 / 2").should == 0.5
  end

  it "understands modulus" do
    evaluate("8 % 3").should == 2.0
  end

  it "understands void" do
    evaluate("void 0").should == nil
  end

  it "understands string literals" do
    evaluate("'foobar'").should == "foobar"
  end

  it "implements typeof" do
    evaluate("typeof 3").should == "number"
    evaluate("typeof null").should == "object"
    evaluate("typeof void 0").should == "undefined"
    evaluate("typeof 'foobar'").should == "string"
  end

  it "implements logical not" do
    evaluate("!true").should == false
    evaluate("!false").should == true
    evaluate("!0").should == true
    evaluate("!1").should == false
    evaluate("!void(0)").should == true
    evaluate("!null").should == true
    evaluate("!''").should == true
    evaluate("!'0'").should == false
    evaluate("!'foobar'").should == false
  end

  it "implements string concatenation with coercion" do
    evaluate("'foo' + 'bar'").should == "foobar"
    evaluate("1 + 'bar'").should == "1bar"
    evaluate("'foo' + 1").should == "foo1"
  end
end
