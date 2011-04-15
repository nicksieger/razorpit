require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/tokenizer'

describe RazorPit::Tokenizer do
  Tokens = RazorPit::Tokenizer::Tokens

  CASES = [["an empty string", "", []],
           ["a number", "3", [Tokens::NUMBER[3]]],
           ["a plus sign", "+", [Tokens::PLUS]],
           ["a minus sign", "-", [Tokens::MINUS]],
           ["a star", "*", [Tokens::TIMES]],
           ["a slash", "/", [Tokens::DIV]],
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
           ["increment", "++", [Tokens::INCREMENT]],
           ["decrement", "--", [Tokens::DECREMENT]],
           ["modulus", "%", [Tokens::MODULUS]],
           ["tilde", "~", [Tokens::BITWISE_NOT]],
           ["bang", "!", [Tokens::NOT]],
           ["assignment", "=", [Tokens::ASSIGN]],
           ["question", "?", [Tokens::QUESTION]],
           ["shift left", "<<", [Tokens::SHIFT_LEFT]],
           ["shift right", ">>", [Tokens::SHIFT_RIGHT]],
           ["shift right (extended)", ">>>", [Tokens::SHIFT_RIGHT_EXTEND]],
           ["and", "&&", [Tokens::AND]],
           ["or", "||", [Tokens::OR]],
           ["booleans", "true false",
            [Tokens::BOOLEAN[true], Tokens::BOOLEAN[false]]],
           ["strict equal", "===", [Tokens::STRICT_EQUAL]],
           ["strict not equal", "!===", [Tokens::STRICT_NOT_EQUAL]],
           ["plus assign", "+=", [Tokens::PLUS_ASSIGN]],
           ["minus assign", "-=", [Tokens::MINUS_ASSIGN]],
           ["times assign", "*=", [Tokens::TIMES_ASSIGN]],
           ["division assign", "/=", [Tokens::DIV_ASSIGN]],
           ["modulus assign", "%=", [Tokens::MODULUS_ASSIGN]],
           ["bitwise or assign", "|=", [Tokens::BITWISE_OR_ASSIGN]],
           ["bitwise and assign", "&=", [Tokens::BITWISE_AND_ASSIGN]],
           ["bitwise xor assign", "^=", [Tokens::BITWISE_XOR_ASSIGN]],
           ["shift left assign", "<<=", [Tokens::SHIFT_LEFT_ASSIGN]],
           ["shift right assign", ">>=", [Tokens::SHIFT_RIGHT_ASSIGN]],
           ["shift right extend assign", ">>>=",
            [Tokens::SHIFT_RIGHT_EXTEND_ASSIGN]],
           ["a simple expression", "1+1",
            [Tokens::NUMBER[1], Tokens::PLUS, Tokens::NUMBER[1]]]]

  CASES.each do |name, string, output|
    it "tokenizes #{name}" do
      RazorPit::Tokenizer.tokenize(string).should == output
    end
  end
end
