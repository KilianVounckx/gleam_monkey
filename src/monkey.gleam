import gleam/erlang
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import monkey/ast
import monkey/lexer
import monkey/parser

type PipelineError {
  Lexer(List(lexer.Error))
  Parser(parser.Error)
}

pub fn main() -> Nil {
  repl()
}

fn repl() -> Nil {
  case erlang.get_line("monkey> ") {
    Error(_) -> io.println("")
    Ok(line) -> {
      pipeline(line)
      repl()
    }
  }
}

fn pipeline(input: String) -> Nil {
  let result = {
    use tokens <- result.try(input |> lexer.lex |> result.map_error(Lexer))
    use ast <- result.try(tokens |> parser.parse |> result.map_error(Parser))
    ast |> ast.to_string |> io.println
    Ok(Nil)
  }
  case result {
    Ok(Nil) -> Nil
    Error(Lexer(errors)) -> {
      errors
      |> list.map(lexer.error_to_string)
      |> string.join("\n")
      |> io.println_error
    }
    Error(Parser(error)) -> {
      error
      |> parser.error_to_string
      |> io.println_error
    }
  }
}
