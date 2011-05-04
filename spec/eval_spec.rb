require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'
require 'razorpit/eval'

describe "#{RazorPit::Eval}.evaluate" do
  def evaluate(string)
    ast = RazorPit::Parser.parse_expression(string)
    RazorPit::Eval.evaluate(ast)
  end

  it "should short-circuit && and ||" do
    RazorPit::Eval.evaluate(RazorPit::Nodes::And[RazorPit::Nodes::Boolean[false], nil])
    RazorPit::Eval.evaluate(RazorPit::Nodes::Or[RazorPit::Nodes::Boolean[true], nil])
  end

  it "should short-circuit ?:" do
    RazorPit::Eval.evaluate(RazorPit::Nodes::Condition[RazorPit::Nodes::Boolean[true],
                                                       RazorPit::Nodes::Number[1],
                                                       nil])
    RazorPit::Eval.evaluate(RazorPit::Nodes::Condition[RazorPit::Nodes::Boolean[false],
                                                       nil,
                                                       RazorPit::Nodes::Number[1]])
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

  it "does ToNumber conversion for addition" do
    evaluate("true + false").should == 1.0
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

  it "does ToNumber conversion for subtraction" do
    evaluate("false - true").should == -1.0
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

  it "implements ternary conditions" do
    evaluate("true ? 1 : 2").should == 1
    evaluate("false ? 1 : 2").should == 2
    evaluate("1 ? 1 : 2").should == 1
    evaluate("0 ? 1 : 2").should == 2
  end

  it "understands bitwise not" do
    evaluate("~3").should == -4
    evaluate("~-1").should == 0
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

  it "implements logical and" do
    evaluate("false && false").should == false
    evaluate("false && true").should == false
    evaluate("true && false").should == false
    evaluate("true && true").should == true
    evaluate("0 && 1").should == 0.0
    evaluate("1 && 0").should == 0.0
  end

  it "implements logical or" do
    evaluate("false || false").should == false
    evaluate("false || true").should == true
    evaluate("true || false").should == true
    evaluate("true || true").should == true
    evaluate("0 || 1").should == 1.0
    evaluate("1 || 0").should == 1.0
  end

  it "implements bitwise and" do
    evaluate("0xff00 & 0x0f0f").should == 0x0f00
  end

  it "implements bitwise xor" do
    evaluate("0xff00 ^ 0x0f0f").should == 0xf00f
  end

  it "implements bitwise or" do
    evaluate("0xff00 | 0x0f0f").should == 0xff0f
  end

  it "implements left shift" do
    evaluate("0xffff0000 << 8").should == 0xff000000 - (1 << 32)
    evaluate("1 << 33").should == 2
    evaluate("1 << -31").should == 2
  end

  it "implements right shift" do
    evaluate("0xff000000 >> 8").should == 0xffff0000 - (1 << 32)
    evaluate("2 >> 33").should == 1
    evaluate("2 >> -31").should == 1
  end

  it "implements unsigned right shift" do
    evaluate("0xff000000 >>> 8").should == 0x00ff0000
    evaluate("2 >>> 33").should == 1
    evaluate("2 >>> -31").should == 1
  end

  it "implements strict equality" do
    evaluate("true === void 0").should be_false
    evaluate("void 0 === null").should be_false
    evaluate("null === void 0").should be_false
    evaluate("void 0 === void 0").should be_true
    evaluate("null === null").should be_true
    evaluate("1.0 === 1.0").should be_true
    evaluate("1.0 === 1.1").should be_false
    evaluate("'foo' === 'foo'").should be_true
    evaluate("'foo' === 'bar'").should be_false
    evaluate("true === true").should be_true
    evaluate("false === true").should be_false

    evaluate("1 !== 1").should be_false
    evaluate("1 !== 2").should be_true
  end

  it "implements abstract equality" do
    evaluate("true == void 0").should be_false
    evaluate("void 0 == null").should be_false
    evaluate("null == void 0").should be_false
    evaluate("void 0 == void 0").should be_true
    evaluate("null == null").should be_true
    evaluate("1.0 == 1.0").should be_true
    evaluate("1.0 == 1.1").should be_false
    evaluate("'foo' == 'foo'").should be_true
    evaluate("'foo' == 'bar'").should be_false
    evaluate("true == true").should be_true
    evaluate("false == true").should be_false

    evaluate("1 != 1").should be_false
    evaluate("1 != 2").should be_true
  end
end

describe "#{RazorPit::Eval}.to_boolean" do
  it "considers undefined to be false" do
    RazorPit::Eval.to_boolean(nil).should be_false
  end

  it "considers null to be false" do
    RazorPit::Eval.to_boolean(RazorPit::NULL).should be_false
  end

  it "considers true to be true and false to be false" do
    RazorPit::Eval.to_boolean(true).should be_true
    RazorPit::Eval.to_boolean(false).should be_false
  end

  it "considers +-0 and NaN to be false" do
    RazorPit::Eval.to_boolean(0.0).should be_false
    RazorPit::Eval.to_boolean(-0.0).should be_false
    RazorPit::Eval.to_boolean(0.0/0.0).should be_false # NaN
  end

  it "considers nonzero numbers to be true" do
    RazorPit::Eval.to_boolean(1.0).should be_true
    RazorPit::Eval.to_boolean(1.0/0.0).should be_true # +Infinity
    RazorPit::Eval.to_boolean(-1.0/0.0).should be_true # -Infinity
  end

  it "considers empty strings to be false" do
    RazorPit::Eval.to_boolean("").should be_false
  end

  it "considers non-empty strings to be true" do
    RazorPit::Eval.to_boolean("foobar").should be_true
  end
end

describe "#{RazorPit::Eval}.to_string" do
  it "returns 'NaN' for NaN" do
    RazorPit::Eval.to_string(0.0/0.0).should == "NaN"
  end

  it "returns +-Infinity for infinities" do
    RazorPit::Eval.to_string(1.0/0.0).should == "Infinity"
    RazorPit::Eval.to_string(-1.0/0.0).should == "-Infinity"
  end

  it "stringifies +-0 to '0'" do
    RazorPit::Eval.to_string(0.0).should == "0"
    RazorPit::Eval.to_string(-0.0).should == "0"
  end

  it "stringifies integers without decimal points" do
    RazorPit::Eval.to_string(1.0).should == "1"
    RazorPit::Eval.to_string(-1.0).should == "-1"
  end

  it "stringifies exact decimals exactly" do
    RazorPit::Eval.to_string(1.25).should == "1.25"
    RazorPit::Eval.to_string(-1.25).should == "-1.25"
  end
end

describe "#{RazorPit::Eval}.to_number" do
  it "converts undefined to NaN" do
    RazorPit::Eval.to_number(nil).should be_nan
  end

  it "converts null to zero" do
    RazorPit::Eval.to_number(RazorPit::NULL).should == 0.0
  end

  it "converts true to 1" do
    RazorPit::Eval.to_number(true).should == 1.0
  end

  it "converts false to 0" do
    RazorPit::Eval.to_number(false).should == 0.0
  end

  it "passes finite and infinite numbers through unchanged" do
    RazorPit::Eval.to_number(1.0/0.0).should be_infinite
    RazorPit::Eval.to_number(1.25).should == 1.25
    RazorPit::Eval.to_number(-1.25).should == -1.25
  end

  it "handles empty strings" do
    RazorPit::Eval.to_number("").should == 0.0
  end

  it "handles strings with only whitespace" do
    RazorPit::Eval.to_number("    ").should == 0.0
  end

  it "handles strings with trailing garbage" do
    RazorPit::Eval.to_number("0foo").should be_nan
  end

  it "handles decimal strings" do
    RazorPit::Eval.to_number("1").should == 1.0
    RazorPit::Eval.to_number("1.0").should == 1.0
    RazorPit::Eval.to_number("1.0e10").should == 1.0e10
    RazorPit::Eval.to_number(".1e10").should == 1.0e9
    RazorPit::Eval.to_number("1.e10").should == 1.0e10
    RazorPit::Eval.to_number("1e10").should == 1.0e10
  end

  it "handles hexadecimal strings" do
    RazorPit::Eval.to_number("0xff").should == 255.0
  end
end

describe "#{RazorPit::Eval}.to_int32" do
  it "passes through 0" do
    RazorPit::Eval.to_int32(-0.0).should == 0.0
    RazorPit::Eval.to_int32(0.0).should == 0.0
  end

  it "returns a float" do
    RazorPit::Eval.to_int32(1.25).should == 1.0
  end

  it "returns 0 for infinite sides" do
    RazorPit::Eval.to_int32(1.0 / 0.0).should == 0.0
    RazorPit::Eval.to_int32(-1.0 / 0.0).should == 0.0
  end

  it "returns 0 for NaN" do
    RazorPit::Eval.to_int32(0.0 / 0.0).should == 0.0
  end

  it "calls to_number" do
    RazorPit::Eval.to_int32("1.0").should == 1.0
  end

  it "rounds numbers correctly" do
    RazorPit::Eval.to_int32(-3.5).should == -3.0
    RazorPit::Eval.to_int32(3.5).should == 3.0
  end

  it "wraps numbers correctly" do
    RazorPit::Eval.to_int32(((1 << 32) - 1).to_f).should == -1
    RazorPit::Eval.to_int32(((2 << 32) - 1).to_f).should == -1
    RazorPit::Eval.to_int32(((1 << 31)).to_f).should == -(1 << 31)
    RazorPit::Eval.to_int32((-(1 << 31) - 1).to_f).should == ((1 << 31) - 1)
  end
end

describe "#{RazorPit::Eval}.to_uint32" do
  it "passes through 0" do
    RazorPit::Eval.to_uint32(-0.0).should == 0.0
    RazorPit::Eval.to_uint32(0.0).should == 0.0
  end

  it "returns a float" do
    RazorPit::Eval.to_uint32(1.25).should == 1.0
  end

  it "returns 0 for infinite sides" do
    RazorPit::Eval.to_uint32(1.0 / 0.0).should == 0.0
    RazorPit::Eval.to_uint32(-1.0 / 0.0).should == 0.0
  end

  it "returns 0 for NaN" do
    RazorPit::Eval.to_uint32(0.0 / 0.0).should == 0.0
  end

  it "calls to_number" do
    RazorPit::Eval.to_uint32("1.0").should == 1.0
  end

  it "rounds numbers correctly" do
    RazorPit::Eval.to_uint32(-3.5).should == (1 << 32) - 3
    RazorPit::Eval.to_uint32(3.5).should == 3.0
  end

  it "wraps numbers correctly" do
    RazorPit::Eval.to_uint32(((1 << 32) - 1).to_f).should == (1 << 32) - 1
    RazorPit::Eval.to_uint32(((2 << 32) - 1).to_f).should == (1 << 32) - 1
    RazorPit::Eval.to_uint32(((1 << 31)).to_f).should == (1 << 31)
    RazorPit::Eval.to_uint32((-(1 << 31) - 1).to_f).should == ((1 << 31) - 1)
  end
end
