require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/tokenizer'

describe RazorPit::Tokenizer do
  it "tokenizes an empty string" do
    RazorPit::Tokenizer.tokenize("").should == []
  end
end
