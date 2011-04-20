require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/parser'

describe RazorPit::Parser do
  it "parses an empty string" do
    ast = RazorPit::Parser.parse("")
    ast.should == RazorPit::Nodes::Program[]
  end
end
