import gleam/int

pub type Token {
  Eof

  Identifier(String)
  String(String)
  Integer(Int)

  LeftBrace
  RightBrace
  LeftBracket
  RightBracket
  LeftParen
  RightParen
  Comma
  Colon
  Dot
  Minus
  Plus
  Slash
  Star

  Bang
  BangEqual
  Equal
  EqualEqual
  Greater
  GreaterEqual
  Less
  LessEqual
  LessGreater
  BarGreater

  And
  Else
  False
  Fun
  If
  In
  Nil
  Let
  Rec
  Then
  True
}

pub fn to_string(token: Token) -> String {
  case token {
    Eof -> "<EOF>"

    Identifier(name) -> name
    String(s) -> "\"" <> s <> "\""
    Integer(n) -> int.to_string(n)

    LeftBrace -> "{"
    RightBrace -> "}"
    LeftBracket -> "["
    RightBracket -> "]"
    LeftParen -> "("
    RightParen -> ")"
    Comma -> ","
    Colon -> ":"
    Dot -> "."
    Minus -> "-"
    Plus -> "+"
    Slash -> "/"
    Star -> "*"

    Bang -> "!"
    BangEqual -> "!="
    Equal -> "="
    EqualEqual -> "=="
    Greater -> ">"
    GreaterEqual -> ">="
    Less -> "<"
    LessEqual -> "<="
    LessGreater -> "<>"
    BarGreater -> "|>"

    And -> "and"
    Else -> "else"
    False -> "false"
    Fun -> "fun"
    If -> "if"
    In -> "in"
    Nil -> "nil"
    Let -> "let"
    Rec -> "rec"
    Then -> "then"
    True -> "true"
  }
}
