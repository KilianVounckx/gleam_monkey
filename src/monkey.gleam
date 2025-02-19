import gleam/erlang
import gleam/io
import monkey/pipeline

pub fn main() -> Nil {
  repl()
}

fn repl() -> Nil {
  case erlang.get_line("monkey> ") {
    Error(_) -> io.println("")
    Ok(line) -> {
      case pipeline.pipeline(line) {
        Ok(Nil) -> Nil
        Error(error) -> error |> pipeline.error_to_string |> io.println_error
      }
      repl()
    }
  }
}
