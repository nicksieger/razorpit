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
end

end
