require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/lexer'

Module.new do

T = RazorPit::Tokens

describe RazorPit::Lexer do

  cases = [["an empty string", "", [T::EOF]],
           ["an integer", "3", [T::NUMBER[3], T::EOF]],
           ["a hex number", "0xf0", [T::NUMBER[0xf0.to_f], T::EOF]],
           ["a simple identifier", "foobar",
            [T::IDENTIFIER["foobar"], T::EOF]],
           ["a camel-case identifier", "fooBar",
            [T::IDENTIFIER["fooBar"], T::EOF]],
           ["a caps-case identifier", "FooBar",
            [T::IDENTIFIER["FooBar"], T::EOF]],
           ["a constant-case identifier", "FOOBAR",
            [T::IDENTIFIER["FOOBAR"], T::EOF]],
           ["an identifier with underscores", "foo_bar",
            [T::IDENTIFIER["foo_bar"], T::EOF]],
           ["an identifier with trailing numbers", "foo64",
            [T::IDENTIFIER["foo64"], T::EOF]],
           ["an identifier with a leading underscore", "_foo",
            [T::IDENTIFIER["_foo"], T::EOF]],
           ["just a dollar sign", "$", [T::IDENTIFIER["$"], T::EOF]],
           ["two dollar signs", "$$", [T::IDENTIFIER["$$"], T::EOF]],
           ["an empty regular expression", "//",
            [T::REGEX[""], T::EOF]],
           ["a simple regular expression", "/foobar/",
            [T::REGEX["foobar"], T::EOF]],
           ["an empty single-quoted string", "''",
            [T::STRING[""], T::EOF]],
           ["an empty double-quoted string", "\"\"",
            [T::STRING[""], T::EOF]],
           ["a simple single-quoted string", "'foo bar'",
            [T::STRING["foo bar"], T::EOF]],
           ["a simple double-quoted string", "\"foo bar\"",
            [T::STRING["foo bar"], T::EOF]],
           ["a token ending with a dollar sign", "foo$",
            [T::IDENTIFIER["foo$"], T::EOF]],
           ["a decimal number", "1.3", [T::NUMBER[1.3], T::EOF]],
           ["a decimal number with no leading digits",
            ".25", [T::NUMBER[0.25], T::EOF]],
           ["a decimal number with no trailing digits",
            "123.", [T::NUMBER[123], T::EOF]],
           ["a decimal number with an exponent",
            "1.0e10", [T::NUMBER[1.0e10], T::EOF]],
           ["a decimal number with a signed positive exponent",
            "1.0e+10", [T::NUMBER[1.0e10], T::EOF]],
           ["a decimal number with a signed negative exponent",
            "1.0e-10", [T::NUMBER[1.0e-10], T::EOF]],
           ["a number with a leading sign",
            "-3", [T::MINUS, T::NUMBER[3], T::EOF]],
           ["a plus sign", "+", [T::PLUS, T::EOF]],
           ["a minus sign", "-", [T::MINUS, T::EOF]],
           ["a star", "*", [T::TIMES, T::EOF]],
           ["a slash", "/", [T::DIV, T::EOF]],
           ["a semicolon", ";", [T::SEMICOLON, T::EOF]],
           ["a colon", ":", [T::COLON, T::EOF]],
           ["a period", ".", [T::PERIOD, T::EOF]],
           ["a comma", ",", [T::COMMA, T::EOF]],
           ["open brace", "{", [T::OPEN_BRACE, T::EOF]],
           ["close brace", "}", [T::CLOSE_BRACE, T::EOF]],
           ["open bracket", "[", [T::OPEN_BRACKET, T::EOF]],
           ["close bracket", "]", [T::CLOSE_BRACKET, T::EOF]],
           ["open parenthesis", "(", [T::OPEN_PAREN, T::EOF]],
           ["close parenthesis", ")", [T::CLOSE_PAREN, T::EOF]],
           ["less than", "<", [T::LT, T::EOF]],
           ["greater than", ">", [T::GT, T::EOF]],
           ["carat", "^", [T::BITWISE_XOR, T::EOF]],
           ["less than or equal", "<=", [T::LTE, T::EOF]],
           ["greater than or equal", ">=", [T::GTE, T::EOF]],
           ["equal", "==", [T::EQUAL, T::EOF]],
           ["not equal", "!=", [T::NOT_EQUAL, T::EOF]],
           ["ampersand", "&", [T::BITWISE_AND, T::EOF]],
           ["pipe", "|", [T::BITWISE_OR, T::EOF]],
           ["increment", "++", [T::INCREMENT, T::EOF]],
           ["decrement", "--", [T::DECREMENT, T::EOF]],
           ["modulus", "%", [T::MODULUS, T::EOF]],
           ["tilde", "~", [T::BITWISE_NOT, T::EOF]],
           ["bang", "!", [T::NOT, T::EOF]],
           ["assignment", "=", [T::ASSIGN, T::EOF]],
           ["question", "?", [T::QUESTION, T::EOF]],
           ["shift left", "<<", [T::SHIFT_LEFT, T::EOF]],
           ["shift right (signed)", ">>", [T::SHIFT_RIGHT_EXTEND, T::EOF]],
           ["shift right (unsigned)", ">>>", [T::SHIFT_RIGHT, T::EOF]],
           ["and", "&&", [T::AND, T::EOF]],
           ["or", "||", [T::OR, T::EOF]],
           ["booleans", "true false",
            [T::BOOLEAN[true], T::BOOLEAN[false], T::EOF]],
           ["strict equal", "===", [T::STRICT_EQUAL, T::EOF]],
           ["strict not equal", "!==", [T::STRICT_NOT_EQUAL, T::EOF]],
           ["plus assign", "+=", [T::PLUS_ASSIGN, T::EOF]],
           ["minus assign", "-=", [T::MINUS_ASSIGN, T::EOF]],
           ["times assign", "*=", [T::TIMES_ASSIGN, T::EOF]],
           ["division assign", "/=", [T::DIV_ASSIGN, T::EOF]],
           ["modulus assign", "%=", [T::MODULUS_ASSIGN, T::EOF]],
           ["bitwise or assign", "|=", [T::BITWISE_OR_ASSIGN, T::EOF]],
           ["bitwise and assign", "&=", [T::BITWISE_AND_ASSIGN, T::EOF]],
           ["bitwise xor assign", "^=", [T::BITWISE_XOR_ASSIGN, T::EOF]],
           ["shift left assign", "<<=", [T::SHIFT_LEFT_ASSIGN, T::EOF]],
           ["shift right assign", ">>=",
            [T::SHIFT_RIGHT_EXTEND_ASSIGN, T::EOF]],
           ["shift right extend assign", ">>>=",
            [T::SHIFT_RIGHT_ASSIGN, T::EOF]],
           ["null", "null", [T::NULL, T::EOF]],
           ["a simple expression", "1+1",
            [T::NUMBER[1], T::PLUS, T::NUMBER[1], T::EOF]],
           ["a simple expression with whitespace", "1 + 1",
            [T::NUMBER[1], T::PLUS, T::NUMBER[1], T::EOF]]]

  cases += %w(break case catch continue debugger default delete do else
              finally for function if in instanceof new return switch this
              throw try typeof var void while with).map { |keyword|
                symbol = keyword.upcase.intern
                ["keyword #{keyword}", keyword, [T.const_get(symbol), T::EOF]]
              }

  cases += %w(class const enum export extends import super).map { |keyword|
                symbol = keyword.upcase.intern
                ["reserved word #{keyword}", keyword,
                 [T.const_get(symbol), T::EOF]]
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
    returned.to_a.should == [T::NUMBER[1], T::EOF]
  end

  it "yields each token if block given" do
    tokens = []
    returned = RazorPit::Lexer.scan("1") do |token|
      tokens << token
    end
    returned.should == RazorPit::Lexer
    tokens.should == [T::NUMBER[1], T::EOF]
  end
end

end
