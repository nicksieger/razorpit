require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'
require 'razorpit/eval'

describe "#{RazorPit::Eval}.evaluate" do
  def evaluate_ast(ast)
    env = RazorPit::Environment.new
    RazorPit::Eval.evaluate(ast, env)
  end

  def program(string)
    ast = RazorPit::Parser.parse(string)
    evaluate_ast(ast)
  end

  def expr(string)
    program("(#{string});")
  end

  it "should short-circuit && and ||" do
    evaluate_ast(RazorPit::Nodes::And[RazorPit::Nodes::Boolean[false], nil])
    evaluate_ast(RazorPit::Nodes::Or[RazorPit::Nodes::Boolean[true], nil])
  end

  it "should short-circuit ?:" do
    evaluate_ast(RazorPit::Nodes::Condition[RazorPit::Nodes::Boolean[true],
                                            RazorPit::Nodes::Number[1],
                                            nil])
    evaluate_ast(RazorPit::Nodes::Condition[
                   RazorPit::Nodes::Boolean[false],
                   nil, RazorPit::Nodes::Number[1]])
  end

  it "can evaluate a trivial expression" do
    expr("1").should == 1.0
  end

  it "can evaluate an unary plus" do
    expr("+8").should == 8
  end

  it "can do trivial arithmetic" do
    expr("1 + 2").should == 3.0
  end

  it "does ToNumber conversion for addition" do
    expr("true + false").should == 1.0
  end

  it "can evaluate true and false" do
    expr("true").should == true
    expr("false").should == false
  end

  it "can evaluate null" do
    expr("null").should == RazorPit::NULL
  end

  it "can do subtraction" do
    expr("2 - 1").should == 1.0
  end

  it "does ToNumber conversion for subtraction" do
    expr("false - true").should == -1.0
  end

  it "understands unary minus" do
    expr("-1").should == -1.0
  end

  it "can do multiplication" do
    expr("2 * 3").should == 6.0
  end

  it "can do division" do
    expr("1 / 2").should == 0.5
  end

  it "understands modulus" do
    expr("8 % 3").should == 2.0
  end

  it "understands void" do
    expr("void 0").should == nil
  end

  it "understands string literals" do
    expr("'foobar'").should == "foobar"
  end

  it "implements ternary conditions" do
    expr("true ? 1 : 2").should == 1
    expr("false ? 1 : 2").should == 2
    expr("1 ? 1 : 2").should == 1
    expr("0 ? 1 : 2").should == 2
  end

  it "understands bitwise not" do
    expr("~3").should == -4
    expr("~-1").should == 0
  end

  it "implements typeof" do
    expr("typeof 3").should == "number"
    expr("typeof null").should == "object"
    expr("typeof void 0").should == "undefined"
    expr("typeof 'foobar'").should == "string"
  end

  it "implements logical not" do
    expr("!true").should == false
    expr("!false").should == true
    expr("!0").should == true
    expr("!1").should == false
    expr("!void(0)").should == true
    expr("!null").should == true
    expr("!''").should == true
    expr("!'0'").should == false
    expr("!'foobar'").should == false
  end

  it "implements string concatenation with coercion" do
    expr("'foo' + 'bar'").should == "foobar"
    expr("1 + 'bar'").should == "1bar"
    expr("'foo' + 1").should == "foo1"
  end

  it "implements logical and" do
    expr("false && false").should == false
    expr("false && true").should == false
    expr("true && false").should == false
    expr("true && true").should == true
    expr("0 && 1").should == 0.0
    expr("1 && 0").should == 0.0
  end

  it "implements logical or" do
    expr("false || false").should == false
    expr("false || true").should == true
    expr("true || false").should == true
    expr("true || true").should == true
    expr("0 || 1").should == 1.0
    expr("1 || 0").should == 1.0
  end

  it "implements bitwise and" do
    expr("0xff00 & 0x0f0f").should == 0x0f00
  end

  it "implements bitwise xor" do
    expr("0xff00 ^ 0x0f0f").should == 0xf00f
  end

  it "implements bitwise or" do
    expr("0xff00 | 0x0f0f").should == 0xff0f
  end

  it "implements left shift" do
    expr("0xffff0000 << 8").should == 0xff000000 - (1 << 32)
    expr("1 << 33").should == 2
    expr("1 << -31").should == 2
  end

  it "implements right shift" do
    expr("0xff000000 >> 8").should == 0xffff0000 - (1 << 32)
    expr("2 >> 33").should == 1
    expr("2 >> -31").should == 1
  end

  it "implements unsigned right shift" do
    expr("0xff000000 >>> 8").should == 0x00ff0000
    expr("2 >>> 33").should == 1
    expr("2 >>> -31").should == 1
  end

  it "implements strict equality" do
    expr("true === void 0").should be_false
    expr("void 0 === null").should be_false
    expr("null === void 0").should be_false
    expr("void 0 === void 0").should be_true
    expr("null === null").should be_true
    expr("1.0 === 1.0").should be_true
    expr("1.0 === 1.1").should be_false
    expr("'foo' === 'foo'").should be_true
    expr("'foo' === 'bar'").should be_false
    expr("true === true").should be_true
    expr("false === true").should be_false

    expr("1 !== 1").should be_false
    expr("1 !== 2").should be_true
  end

  it "implements abstract equality" do
    expr("true == void 0").should be_false
    expr("void 0 == null").should be_false
    expr("null == void 0").should be_false
    expr("void 0 == void 0").should be_true
    expr("null == null").should be_true
    expr("1.0 == 1.0").should be_true
    expr("1.0 == 1.1").should be_false
    expr("'foo' == 'foo'").should be_true
    expr("'foo' == 'bar'").should be_false
    expr("true == true").should be_true
    expr("false == true").should be_false

    expr("1 != 1").should be_false
    expr("1 != 2").should be_true
  end

  it "implements the greater-than operator" do
    expr("2 > 3").should be_false
    expr("3 > 3").should be_false
    expr("3 > 2").should be_true
  end

  it "implements the less-than operator" do
    expr("2 < 3").should be_true
    expr("3 < 3").should be_false
    expr("3 < 2").should be_false
  end

  it "implements the greater-than-or-equal operator" do
    expr("2 >= 3").should be_false
    expr("3 >= 3").should be_true
    expr("3 >= 2").should be_true
  end

  it "implements the less-than-or-equal operator" do
    expr("2 <= 3").should be_true
    expr("3 <= 3").should be_true
    expr("3 <= 2").should be_false
  end

  it "handles relational comparison with strings" do
    expr("'03' > 2").should be_true
    expr("'03' > '2'").should be_false
    expr("-1 > '-2'").should be_true
    expr("'-1' > '-2'").should be_false
  end

  it "implements the comma operator" do
    expr("1, 2").should == 2
  end

  it "deals with unbound variables" do
    expr("foobar").should be_nil
  end

  it "returns the value of an assignment" do
    expr("foo = 2").should == 2
  end

  it "implements assignment" do
    expr("foo = 2, foo").should == 2
  end

  it "implements +=" do
    expr("foo = 2, foo += 3, foo").should == 5
  end

  it "implements -=" do
    expr("foo = 3, foo -= 2, foo").should == 1
  end

  it "implements *=" do
    expr("foo = 3, foo *= 2, foo").should == 6
  end

  it "implements /=" do
    expr("foo = 6, foo /= 2, foo").should == 3
  end

  it "implements %=" do
    expr("foo = 6, foo %= 5, foo").should == 1
  end

  it "implements <<=" do
    expr("foo = 1, foo <<= 1, foo").should == 2
  end

  it "implements >>=" do
    expr("foo = 8, foo >>= 1, foo").should == 4
  end

  it "implements >>>=" do
    expr("foo = 8, foo >>= 1, foo").should == 4
  end

  it "implements &=" do
    expr("foo = 0xff00, foo &= 0xf0f0, foo").should == 0xf000
  end

  it "implements |=" do
    expr("foo = 0xff00, foo |= 0xf0f0, foo").should == 0xfff0
  end

  it "implements ^=" do
    expr("foo = 0xff00, foo ^= 0xf0f0, foo").should == 0x0ff0
  end

  it "implements preincrement" do
    expr("foo = 1, ++foo").should == 2
    expr("foo = 1, ++foo, foo").should == 2
  end

  it "implements postincrement" do
    expr("foo = 1, foo++").should == 1
    expr("foo = 1, foo++, foo").should == 2
  end

  it "implements predecrement" do
    expr("foo = 1, --foo").should == 0
    expr("foo = 1, --foo, foo").should == 0
  end

  it "implements postdecrement" do
    expr("foo = 1, foo--").should == 1
    expr("foo = 1, foo--, foo").should == 0
  end

  it "implements delete for variables" do
    expr("delete foo").should be_true
    expr("foo = 1, delete foo").should be_true
    expr("foo = 1, delete foo, foo").should be_nil
  end

  it "implements block scopes with variable shadowing" do
    result = program <<-EOS
      var foo=3;
      {
        var foo=4;
        foo;
      }
    EOS
    result.should == 4
    result = program <<-EOS
      var foo=3;
      {
        var foo=4;
      }
      foo;
    EOS
    result.should == 3;
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
