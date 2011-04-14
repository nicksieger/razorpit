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
           ["open brace", "{", [Tokens::OBRACE[]]],
           ["close brace", "}", [Tokens::CBRACE[]]],
           ["open bracket", "[", [Tokens::OBRACKET[]]],
           ["close bracket", "]", [Tokens::CBRACKET[]]],
           ["open parenthesis", "(", [Tokens::OPAREN[]]],
           ["close parenthesis", ")", [Tokens::CPAREN[]]],
           ["less than", "<", [Tokens::LT[]]],
           ["greater than", ">", [Tokens::GT[]]],
           ["carat", "^", [Tokens::BITWISE_XOR[]]],
           ["less than or equal", "<=", [Tokens::LTE[]]],
           ["greater than or equal", ">=", [Tokens::GTE[]]],
           ["equal", "==", [Tokens::EQUAL[]]],
           ["not equal", "!=", [Tokens::NEQUAL[]]],
           ["ampersand", "&", [Tokens::BITWISE_AND[]]],
           ["pipe", "|", [Tokens::BITWISE_OR[]]],
           ["a simple expression", "1+1",
            [Tokens::NUMBER[1], Tokens::PLUS[], Tokens::NUMBER[1]]]]

  CASES.each do |name, string, output|
    it "tokenizes #{name}" do
      RazorPit::Tokenizer.tokenize(string).should == output
    end
  end
end
