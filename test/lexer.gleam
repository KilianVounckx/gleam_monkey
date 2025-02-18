import gleeunit/should
import monkey/lexer
import monkey/token

pub fn lex_test() {
  "let five = 5 in
let ten = 10 in
let add = fn(x, y) x + y in
let result = add(five, ten) in
result
let rec and
!-/*5
5 < 10 > 5
if (5 < 10) then true else false
10 == 10
10 != 9
! != = == > >= < <=
"
  |> lexer.lex
  |> should.be_ok
  |> should.equal([
    token.Let,
    token.Identifier("five"),
    token.Equal,
    token.Integer(5),
    token.In,
    token.Let,
    token.Identifier("ten"),
    token.Equal,
    token.Integer(10),
    token.In,
    token.Let,
    token.Identifier("add"),
    token.Equal,
    token.Identifier("fn"),
    token.LeftParen,
    token.Identifier("x"),
    token.Comma,
    token.Identifier("y"),
    token.RightParen,
    token.Identifier("x"),
    token.Plus,
    token.Identifier("y"),
    token.In,
    token.Let,
    token.Identifier("result"),
    token.Equal,
    token.Identifier("add"),
    token.LeftParen,
    token.Identifier("five"),
    token.Comma,
    token.Identifier("ten"),
    token.RightParen,
    token.In,
    token.Identifier("result"),
    token.Let,
    token.Rec,
    token.And,
    token.Bang,
    token.Minus,
    token.Slash,
    token.Star,
    token.Integer(5),
    token.Integer(5),
    token.Less,
    token.Integer(10),
    token.Greater,
    token.Integer(5),
    token.If,
    token.LeftParen,
    token.Integer(5),
    token.Less,
    token.Integer(10),
    token.RightParen,
    token.Then,
    token.True,
    token.Else,
    token.False,
    token.Integer(10),
    token.EqualEqual,
    token.Integer(10),
    token.Integer(10),
    token.BangEqual,
    token.Integer(9),
    token.Bang,
    token.BangEqual,
    token.Equal,
    token.EqualEqual,
    token.Greater,
    token.GreaterEqual,
    token.Less,
    token.LessEqual,
    token.Eof,
  ])
}
