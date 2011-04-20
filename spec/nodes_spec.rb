require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/nodes'

Module.new do

N = RazorPit::Nodes

describe "#{RazorPit::Node}#==" do
  it "considers two equivalent program instances to be equal" do
    N::Program[].should == N::Program[]
  end

  it "considers two number instances with equal values to be equal" do
    N::Number[1].should == N::Number[1]
  end

  it "considers two number instances with different values to be not equal" do
    N::Number[1].should_not == N::Number[2]
  end

  it "has a == method which distinguishes node classes" do
    N::Program[].should_not == N::Number[1]
  end

  it "should consider two additions with equal parameters to be equal" do
    N::Add[N::Number[1], N::Number[2]].should == N::Add[N::Number[1], N::Number[2]]
  end

  it "should consider two additions with different parameters to be different" do
    N::Add[N::Number[1], N::Number[2]].should_not == N::Add[N::Number[2], N::Number[1]]
  end
end

end
