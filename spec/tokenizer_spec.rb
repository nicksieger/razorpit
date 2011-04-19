require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'razorpit/tokenizer'

describe RazorPit::Tokenizer do
  Tokens = RazorPit::Tokenizer::Tokens

  cases = [["an empty string", "", []],
           ["an integer", "3", [Tokens::NUMBER[3]]],
           ["a hex number", "0xf0", [Tokens::NUMBER[0xf0.to_f]]],
           ["a simple identifier", "foobar", [Tokens::IDENTIFIER["foobar"]]],
           ["a camel-case identifier", "fooBar",
            [Tokens::IDENTIFIER["fooBar"]]],
           ["a caps-case identifier", "FooBar",
            [Tokens::IDENTIFIER["FooBar"]]],
           ["a constant-case identifier", "FOOBAR",
            [Tokens::IDENTIFIER["FOOBAR"]]],
           ["an identifier with underscores", "foo_bar",
            [Tokens::IDENTIFIER["foo_bar"]]],
           ["an identifier with trailing numbers", "foo64",
            [Tokens::IDENTIFIER["foo64"]]],
           ["an identifier with a leading underscore", "_foo",
            [Tokens::IDENTIFIER["_foo"]]],
           ["just a dollar sign", "$", [Tokens::IDENTIFIER["$"]]],
           ["two dollar signs", "$$", [Tokens::IDENTIFIER["$$"]]],
           ["an empty single-quoted string", "''", [Tokens::STRING[""]]],
           ["an empty double-quoted string", "\"\"", [Tokens::STRING[""]]],
           ["a simple single-quoted string", "'foo bar'",
            [Tokens::STRING["foo bar"]]],
           ["a simple double-quoted string", "\"foo bar\"",
            [Tokens::STRING["foo bar"]]],
           ["a token ending with a dollar sign", "foo$",
            [Tokens::IDENTIFIER["foo$"]]],
           ["a decimal number", "1.3", [Tokens::NUMBER[1.3]]],
           ["a decimal number with no leading digits",
            ".25", [Tokens::NUMBER[0.25]]],
           ["a decimal number with no trailing digits",
            "123.", [Tokens::NUMBER[123]]],
           ["a decimal number with an exponent",
            "1.0e10", [Tokens::NUMBER[1.0e10]]],
           ["a decimal number with a signed positive exponent",
            "1.0e+10", [Tokens::NUMBER[1.0e10]]],
           ["a decimal number with a signed negative exponent",
            "1.0e-10", [Tokens::NUMBER[1.0e-10]]],
           ["a number with a leading sign",
            "-3", [Tokens::MINUS, Tokens::NUMBER[3]]],
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
           ["null", "null", [Tokens::NULL]],
           ["a simple expression", "1+1",
            [Tokens::NUMBER[1], Tokens::PLUS, Tokens::NUMBER[1]]]]

  cases += %w(break case catch continue debugger default delete do else
              finally for function if in instanceof new return switch this
              throw try typeof var void while with).map { |keyword|
                symbol = keyword.upcase.intern
                ["keyword #{keyword}", keyword, [Tokens.const_get(symbol)]]
              }

  cases += %w(class const enum export extends import super).map { |keyword|
                symbol = keyword.upcase.intern
                ["reserved word #{keyword}", keyword,
                 [Tokens.const_get(symbol)]]
              }

  cases.each do |name, string, output|
    it "tokenizes #{name}" do
      RazorPit::Tokenizer.tokenize(string).to_a.should == output
    end
  end
end
