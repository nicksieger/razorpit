require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/tokenizer'

describe RazorPit::Tokenizer do
  Tokens = RazorPit::Tokenizer::Tokens

  CASES = [["an empty string", "", []],
           ["a number", "3", [Tokens::NUMBER[3]]],
           ["a plus sign", "+", [Tokens::PLUS[]]]]

  CASES.each do |name, string, output|
    it "tokenizes #{name}" do
      RazorPit::Tokenizer.tokenize(string).should == output
    end
  end
end
