require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/nodes'

Module.new do

describe "#{RazorPit::Node}#==" do
  const_set :N, RazorPit::Nodes

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

  it "considers two additions with equal parameters to be equal" do
    N::Add[N::Number[1], N::Number[2]].should == N::Add[N::Number[1], N::Number[2]]
  end

  it "considers two additions with different parameters to be different" do
    N::Add[N::Number[1], N::Number[2]].should_not == N::Add[N::Number[2], N::Number[1]]
  end

  it "considers two booleans with the same value to be equal" do
    N::Boolean[true].should == N::Boolean[true]
  end

  it "considers two booleans with different parameters to be different" do
    N::Boolean[false].should_not == N::Boolean[true]
  end

  it "considers null equal to itself" do
    N::NULL.should == N::NULL
  end

  it "considers null not equal to other types" do
    N::NULL.should_not == N::Boolean[true]
  end
end

end
