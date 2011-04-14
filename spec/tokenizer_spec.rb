require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/tokenizer'

describe RazorPit::Tokenizer do
  Tokens = RazorPit::Tokenizer::Tokens

  CASES = [["an empty string", "", []],
           ["a number", "3", [Tokens::NUMBER[3]]],
           ["a plus sign", "+", [Tokens::PLUS[]]],
           ["a minus sign", "-", [Tokens::MINUS[]]],
           ["a star", "*", [Tokens::TIMES[]]],
           ["a slash", "/", [Tokens::DIVISION[]]],
           ["a semicolon", ";", [Tokens::SEMICOLON[]]],
           ["a colon", ":", [Tokens::COLON[]]],
           ["a period", ".", [Tokens::PERIOD[]]],
           ["a comma", ",", [Tokens::COMMA[]]],
           ["a simple expression", "1+1",
            [Tokens::NUMBER[1], Tokens::PLUS[], Tokens::NUMBER[1]]]]

  CASES.each do |name, string, output|
    it "tokenizes #{name}" do
      RazorPit::Tokenizer.tokenize(string).should == output
    end
  end
end
