require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'

Module.new do

N = RazorPit::Nodes

describe RazorPit::Parser do
  it "parses an empty program" do
    ast = RazorPit::Parser.parse("")
    ast.should == N::Program[]
  end

  it "parses an expression" do
    ast = RazorPit::Parser.parse_expression("1")
    ast.should == N::Number[1]
  end

  xit "parses an addition expression" do
    ast = RazorPit::Parser.parse_expression("1 + 2")
    ast.should == N::Add[N::Number[1], N::Number[2]]
  end
end

end
