import gleam/erlang
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import monkey/lexer
import monkey/token

type PipelineError {
  Lexer(List(lexer.Error))
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
    tokens |> list.map(token.to_string) |> string.join(" ") |> io.println
    Ok(Nil)
  }
  case result {
    Ok(Nil) -> Nil
    Error(Lexer(errors)) -> {
      errors
      |> list.map(lexer.error_to_string)
      |> string.join("\n")
      |> io.println
    }
  }
}
