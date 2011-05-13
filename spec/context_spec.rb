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

  it "should evaluate multiple statements" do
    @ctx.eval("1; 2").should == 2.0
  end

  it "evaluates a trivial expression" do
    @ctx.eval("1").should == 1.0
  end

  it "returns numbers as floats" do
    result = @ctx.eval("1")
    result.should be_an_instance_of(Float)
  end

  it "returns strings as strings" do
    result = @ctx.eval("'foo'")
    result.should be_an_instance_of(String)
  end

  it "returns booleans as booleans" do
    result = @ctx.eval("true")
    result.should be_true
    result = @ctx.eval("false")
    result.should be_false
  end

  it "returns undefined as nil" do
    result = @ctx.eval("void 0")
    result.should be_nil
  end

  it "returns null as nil" do
    result = @ctx.eval("null")
    result.should be_nil
  end
end

end
