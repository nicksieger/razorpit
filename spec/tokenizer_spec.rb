require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/tokenizer'

describe RazorPit::Tokenizer do
  Tokens = RazorPit::Tokenizer::Tokens

  CASES = [["an empty string", "", []],
           ["a number", "3", [Tokens::NUMBER[3]]],
           ["a plus sign", "+", [Tokens::PLUS]],
           ["a minus sign", "-", [Tokens::MINUS]],
           ["a star", "*", [Tokens::TIMES]],
           ["a slash", "/", [Tokens::DIVISION]],
           ["a semicolon", ";", [Tokens::SEMICOLON]],
           ["a colon", ":", [Tokens::COLON]],
           ["a period", ".", [Tokens::PERIOD]],
           ["a comma", ",", [Tokens::COMMA]],
           ["open brace", "{", [Tokens::OPEN_BRACE]],
           ["close brace", "}", [Tokens::CLOSE_BRACE]],
           ["open bracket", "[", [Tokens::OPEN_BRACKET]],
           ["close bracket", "]", [Tokens::CLOSE_BRACKET]],
           ["open parenthesis", "(", [Tokens::OPEN_PAREN]],
           ["close parenthesis", ")", [Tokens::CLOSE_PAREN]],
           ["less than", "<", [Tokens::LT]],
           ["greater than", ">", [Tokens::GT]],
           ["carat", "^", [Tokens::BITWISE_XOR]],
           ["less than or equal", "<=", [Tokens::LTE]],
           ["greater than or equal", ">=", [Tokens::GTE]],
           ["equal", "==", [Tokens::EQUAL]],
           ["not equal", "!=", [Tokens::NOT_EQUAL]],
           ["ampersand", "&", [Tokens::BITWISE_AND]],
           ["pipe", "|", [Tokens::BITWISE_OR]],
           ["a simple expression", "1+1",
            [Tokens::NUMBER[1], Tokens::PLUS, Tokens::NUMBER[1]]]]

  CASES.each do |name, string, output|
    it "tokenizes #{name}" do
      RazorPit::Tokenizer.tokenize(string).should == output
    end
  end
end
