require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/lexer'

Module.new do

T = RazorPit::Tokens

describe RazorPit::Lexer do

  cases = [["an empty string", "", []],
           ["an integer", "3", [T::NUMBER[3]]],
           ["a hex number", "0xf0", [T::NUMBER[0xf0.to_f]]],
           ["a simple identifier", "foobar", [T::IDENTIFIER["foobar"]]],
           ["a camel-case identifier", "fooBar",
            [T::IDENTIFIER["fooBar"]]],
           ["a caps-case identifier", "FooBar",
            [T::IDENTIFIER["FooBar"]]],
           ["a constant-case identifier", "FOOBAR",
            [T::IDENTIFIER["FOOBAR"]]],
           ["an identifier with underscores", "foo_bar",
            [T::IDENTIFIER["foo_bar"]]],
           ["an identifier with trailing numbers", "foo64",
            [T::IDENTIFIER["foo64"]]],
           ["an identifier with a leading underscore", "_foo",
            [T::IDENTIFIER["_foo"]]],
           ["just a dollar sign", "$", [T::IDENTIFIER["$"]]],
           ["two dollar signs", "$$", [T::IDENTIFIER["$$"]]],
           ["an empty single-quoted string", "''", [T::STRING[""]]],
           ["an empty double-quoted string", "\"\"", [T::STRING[""]]],
           ["a simple single-quoted string", "'foo bar'",
            [T::STRING["foo bar"]]],
           ["a simple double-quoted string", "\"foo bar\"",
            [T::STRING["foo bar"]]],
           ["a token ending with a dollar sign", "foo$",
            [T::IDENTIFIER["foo$"]]],
           ["a decimal number", "1.3", [T::NUMBER[1.3]]],
           ["a decimal number with no leading digits",
            ".25", [T::NUMBER[0.25]]],
           ["a decimal number with no trailing digits",
            "123.", [T::NUMBER[123]]],
           ["a decimal number with an exponent",
            "1.0e10", [T::NUMBER[1.0e10]]],
           ["a decimal number with a signed positive exponent",
            "1.0e+10", [T::NUMBER[1.0e10]]],
           ["a decimal number with a signed negative exponent",
            "1.0e-10", [T::NUMBER[1.0e-10]]],
           ["a number with a leading sign",
            "-3", [T::MINUS, T::NUMBER[3]]],
           ["a plus sign", "+", [T::PLUS]],
           ["a minus sign", "-", [T::MINUS]],
           ["a star", "*", [T::TIMES]],
           ["a slash", "/", [T::DIV]],
           ["a semicolon", ";", [T::SEMICOLON]],
           ["a colon", ":", [T::COLON]],
           ["a period", ".", [T::PERIOD]],
           ["a comma", ",", [T::COMMA]],
           ["open brace", "{", [T::OPEN_BRACE]],
           ["close brace", "}", [T::CLOSE_BRACE]],
           ["open bracket", "[", [T::OPEN_BRACKET]],
           ["close bracket", "]", [T::CLOSE_BRACKET]],
           ["open parenthesis", "(", [T::OPEN_PAREN]],
           ["close parenthesis", ")", [T::CLOSE_PAREN]],
           ["less than", "<", [T::LT]],
           ["greater than", ">", [T::GT]],
           ["carat", "^", [T::BITWISE_XOR]],
           ["less than or equal", "<=", [T::LTE]],
           ["greater than or equal", ">=", [T::GTE]],
           ["equal", "==", [T::EQUAL]],
           ["not equal", "!=", [T::NOT_EQUAL]],
           ["ampersand", "&", [T::BITWISE_AND]],
           ["pipe", "|", [T::BITWISE_OR]],
           ["increment", "++", [T::INCREMENT]],
           ["decrement", "--", [T::DECREMENT]],
           ["modulus", "%", [T::MODULUS]],
           ["tilde", "~", [T::BITWISE_NOT]],
           ["bang", "!", [T::NOT]],
           ["assignment", "=", [T::ASSIGN]],
           ["question", "?", [T::QUESTION]],
           ["shift left", "<<", [T::SHIFT_LEFT]],
           ["shift right", ">>", [T::SHIFT_RIGHT]],
           ["shift right (extended)", ">>>", [T::SHIFT_RIGHT_EXTEND]],
           ["and", "&&", [T::AND]],
           ["or", "||", [T::OR]],
           ["booleans", "true false",
            [T::BOOLEAN[true], T::BOOLEAN[false]]],
           ["strict equal", "===", [T::STRICT_EQUAL]],
           ["strict not equal", "!===", [T::STRICT_NOT_EQUAL]],
           ["plus assign", "+=", [T::PLUS_ASSIGN]],
           ["minus assign", "-=", [T::MINUS_ASSIGN]],
           ["times assign", "*=", [T::TIMES_ASSIGN]],
           ["division assign", "/=", [T::DIV_ASSIGN]],
           ["modulus assign", "%=", [T::MODULUS_ASSIGN]],
           ["bitwise or assign", "|=", [T::BITWISE_OR_ASSIGN]],
           ["bitwise and assign", "&=", [T::BITWISE_AND_ASSIGN]],
           ["bitwise xor assign", "^=", [T::BITWISE_XOR_ASSIGN]],
           ["shift left assign", "<<=", [T::SHIFT_LEFT_ASSIGN]],
           ["shift right assign", ">>=", [T::SHIFT_RIGHT_ASSIGN]],
           ["shift right extend assign", ">>>=",
            [T::SHIFT_RIGHT_EXTEND_ASSIGN]],
           ["null", "null", [T::NULL]],
           ["a simple expression", "1+1",
            [T::NUMBER[1], T::PLUS, T::NUMBER[1]]],
           ["a simple expression with whitespace", "1 + 1",
            [T::NUMBER[1], T::PLUS, T::NUMBER[1]]]]

  cases += %w(break case catch continue debugger default delete do else
              finally for function if in instanceof new return switch this
              throw try typeof var void while with).map { |keyword|
                symbol = keyword.upcase.intern
                ["keyword #{keyword}", keyword, [T.const_get(symbol)]]
              }

  cases += %w(class const enum export extends import super).map { |keyword|
                symbol = keyword.upcase.intern
                ["reserved word #{keyword}", keyword, [T.const_get(symbol)]]
              }

  cases.each do |name, string, output|
    it "tokenizes #{name}" do
      RazorPit::Lexer.scan(string).to_a.should == output
    end
  end
end

describe "#{RazorPit::Lexer}.scan" do
  it "raises an exception when it encounters an invalid token" do
    lambda {
      RazorPit::Lexer.scan("@").to_a
    }.should raise_error(RazorPit::Lexer::InvalidToken)
  end

  it "returns an enumerator if no block given" do
    returned = RazorPit::Lexer.scan("1")
    returned.should be_a_kind_of(Enumerator)
    returned.to_a.should == [T::NUMBER[1]]
  end

  it "yields each token if block given" do
    tokens = []
    returned = RazorPit::Lexer.scan("1") do |token|
      tokens << token
    end
    returned.should == RazorPit::Lexer
    tokens.should == [T::NUMBER[1]]
  end
end

end
