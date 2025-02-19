import gleam/io
import gleam/list
import gleam/result
import gleam/string
import monkey/evaluator
import monkey/lexer
import monkey/parser
import monkey/value.{Empty}

pub type Error {
  Lexer(List(lexer.Error))
  Parser(parser.Error)
  Evaluator(evaluator.Error)
}

pub fn error_to_string(error: Error) -> String {
  case error {
    Lexer(errors) -> {
      errors
      |> list.map(lexer.error_to_string)
      |> string.join("\n")
    }
    Parser(error) -> {
      error
      |> parser.error_to_string
    }
    Evaluator(error) -> {
      error
      |> evaluator.error_to_string
    }
  }
}

pub fn pipeline(input: String) -> Result(Nil, Error) {
  use tokens <- result.try(input |> lexer.lex |> result.map_error(Lexer))
  use ast <- result.try(tokens |> parser.parse |> result.map_error(Parser))
  use value <- result.try(
    ast |> evaluator.eval(Empty) |> result.map_error(Evaluator),
  )
  value |> value.to_string |> io.println
  Ok(Nil)
}
