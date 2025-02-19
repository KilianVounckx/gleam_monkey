import gleam/int

pub type Token {
  Eof

  Identifier(String)
  String(String)
  Integer(Int)

  LeftParen
  RightParen
  Comma
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

    LeftParen -> "("
    RightParen -> ")"
    Comma -> ","
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
