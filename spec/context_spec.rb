require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/context'

Module.new do

describe RazorPit::Context do
  it "can be instantiated" do
    ctx = RazorPit::Context.new
    ctx.should be_an_instance_of(RazorPit::Context)
  end
end

describe "#{RazorPit::Context}#eval" do
  before :each do
    @ctx = RazorPit::Context.new
  end

  it "can evaluate a trivial expression" do
    @ctx.eval("1").should == 1.0
  end

  it "can evaluate an unary plus" do
    @ctx.eval("+8").should == 8
  end

  it "can do trivial arithmetic" do
    @ctx.eval("1 + 2").should == 3.0
  end

  it "can evaluate true and false" do
    @ctx.eval("true").should == true
    @ctx.eval("false").should == false
  end

  it "can evaluate null" do
    @ctx.eval("null").should == RazorPit::NULL
  end

  it "can do subtraction" do
    @ctx.eval("2 - 1").should == 1.0
  end

  it "understands unary minus" do
    @ctx.eval("-1").should == -1.0
  end

  it "can do multiplication" do
    @ctx.eval("2 * 3").should == 6.0
  end

  it "can do division" do
    @ctx.eval("1 / 2").should == 0.5
  end

  it "understands modulus" do
    @ctx.eval("8 % 3").should == 2.0
  end

  it "understands void" do
    @ctx.eval("void 0").should == nil
  end

  it "understands string literals" do
    @ctx.eval("'foobar'").should == "foobar"
  end

  it "implements typeof" do
    @ctx.eval("typeof 3").should == "number"
    @ctx.eval("typeof null").should == "object"
    @ctx.eval("typeof void 0").should == "undefined"
    @ctx.eval("typeof 'foobar'").should == "string"
  end

  it "implements logical not" do
    @ctx.eval("!true").should == false
    @ctx.eval("!false").should == true
    @ctx.eval("!0").should == true
    @ctx.eval("!1").should == false
    @ctx.eval("!void(0)").should == true
    @ctx.eval("!null").should == true
    @ctx.eval("!''").should == true
    @ctx.eval("!'0'").should == false
    @ctx.eval("!'foobar'").should == false
  end
end

end
