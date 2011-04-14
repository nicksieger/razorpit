require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/tokenizer'

describe RazorPit::Tokenizer do
  Tokens = RazorPit::Tokenizer::Tokens

  it "tokenizes an empty string" do
    RazorPit::Tokenizer.tokenize("").should == []
  end

  it "tokenizes a number" do
    RazorPit::Tokenizer.tokenize("3").should == [Tokens::NUMBER[3]]
  end

  it "tokenizes a plus sign" do
    RazorPit::Tokenizer.tokenize("+").should == [Tokens::PLUS[]]
  end
end
