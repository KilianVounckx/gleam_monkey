import gleam/int
import gleam/list
import gleam/result
import gleam/string
import monkey/token.{type Token}

pub type Error {
  UnexpectedCharacter(String)
  InvalidInteger(String)
}

pub fn error_to_string(error: Error) -> String {
  case error {
    UnexpectedCharacter(c) -> "unexpected character: '" <> c <> "'"
    InvalidInteger(lexeme) -> "integer not representable: " <> lexeme
  }
}

pub fn lex(input: String) -> Result(List(Token), List(Error)) {
  let #(tokens, errors) =
    do_lex(
      [],
      input
        |> string.to_graphemes,
    )
    |> result.partition
  case errors {
    [] -> Ok(tokens)
    _ -> Error(errors)
  }
}

fn do_lex(
  acc: List(Result(Token, Error)),
  chars: List(String),
) -> List(Result(Token, Error)) {
  case chars {
    [] -> [Ok(token.Eof), ..acc]
    [" ", ..rest] -> acc |> do_lex(rest)
    ["\t", ..rest] -> acc |> do_lex(rest)
    ["\r", ..rest] -> acc |> do_lex(rest)
    ["\n", ..rest] -> acc |> do_lex(rest)
    ["[", ..rest] -> [Ok(token.LeftBracket), ..acc] |> do_lex(rest)
    ["]", ..rest] -> [Ok(token.RightBracket), ..acc] |> do_lex(rest)
    ["(", ..rest] -> [Ok(token.LeftParen), ..acc] |> do_lex(rest)
    [")", ..rest] -> [Ok(token.RightParen), ..acc] |> do_lex(rest)
    [",", ..rest] -> [Ok(token.Comma), ..acc] |> do_lex(rest)
    ["-", ..rest] -> [Ok(token.Minus), ..acc] |> do_lex(rest)
    ["+", ..rest] -> [Ok(token.Plus), ..acc] |> do_lex(rest)
    ["/", ..rest] -> [Ok(token.Slash), ..acc] |> do_lex(rest)
    ["*", ..rest] -> [Ok(token.Star), ..acc] |> do_lex(rest)
    ["!", "=", ..rest] -> [Ok(token.BangEqual), ..acc] |> do_lex(rest)
    ["!", ..rest] -> [Ok(token.Bang), ..acc] |> do_lex(rest)
    ["=", "=", ..rest] -> [Ok(token.EqualEqual), ..acc] |> do_lex(rest)
    ["=", ..rest] -> [Ok(token.Equal), ..acc] |> do_lex(rest)
    [">", "=", ..rest] -> [Ok(token.GreaterEqual), ..acc] |> do_lex(rest)
    [">", ..rest] -> [Ok(token.Greater), ..acc] |> do_lex(rest)
    ["<", "=", ..rest] -> [Ok(token.LessEqual), ..acc] |> do_lex(rest)
    ["<", ">", ..rest] -> [Ok(token.LessGreater), ..acc] |> do_lex(rest)
    ["<", ..rest] -> [Ok(token.Less), ..acc] |> do_lex(rest)
    ["\"", ..rest] -> {
      let #(before, rest) = rest |> list.split_while(fn(c) { c != "\"" })
      let string = before |> string.join("")
      [Ok(token.String(string)), ..acc] |> do_lex(rest |> list.drop(1))
    }
    [c, ..rest] ->
      case is_digit(c) {
        True -> {
          let #(before, rest) = chars |> list.split_while(is_digit)
          let lexeme = before |> string.join("")
          case int.parse(lexeme) {
            Ok(n) -> [Ok(token.Integer(n)), ..acc] |> do_lex(rest)
            Error(_) -> [Error(InvalidInteger(lexeme)), ..acc] |> do_lex(rest)
          }
        }
        False ->
          case is_alpha(c) {
            True -> {
              let #(before, rest) =
                chars |> list.split_while(fn(c) { is_digit(c) || is_alpha(c) })
              let lexeme = before |> string.join("")
              let token = keywords(lexeme)
              [Ok(token), ..acc] |> do_lex(rest)
            }
            False -> [Error(UnexpectedCharacter(c)), ..acc] |> do_lex(rest)
          }
      }
  }
}

fn keywords(lexeme: String) -> Token {
  case lexeme {
    "and" -> token.And
    "else" -> token.Else
    "false" -> token.False
    "fun" -> token.Fun
    "if" -> token.If
    "in" -> token.In
    "nil" -> token.Nil
    "let" -> token.Let
    "rec" -> token.Rec
    "then" -> token.Then
    "true" -> token.True
    _ -> token.Identifier(lexeme)
  }
}

fn is_digit(c: String) -> Bool {
  "0123456789" |> string.to_graphemes |> list.contains(c)
}

fn is_alpha(c: String) -> Bool {
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_"
  |> string.to_graphemes
  |> list.contains(c)
}
