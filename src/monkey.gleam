import argv
import clip
import clip/arg
import clip/help
import clip/opt
import gleam/erlang
import gleam/io
import monkey/pipeline
import simplifile

type Args {
  Args(expression: Result(String, Nil), filename: Result(String, Nil))
}

fn args() {
  clip.command({
    use expression <- clip.parameter
    use filename <- clip.parameter
    Args(expression:, filename:)
  })
  |> clip.opt(
    opt.new("expression")
    |> opt.short("e")
    |> opt.help(
      "Specify the expression to execute. Other arguments are ignored.",
    )
    |> opt.optional,
  )
  |> clip.arg(
    arg.new("filename")
    |> arg.help("The file to read from, else run a repl.")
    |> arg.optional,
  )
  |> clip.help(help.simple("monkey", "A simple programming language."))
}

pub fn main() -> Nil {
  case args() |> clip.run(argv.load().arguments) {
    Error(message) -> io.println_error(message)
    Ok(args) -> {
      case args {
        Args(expression: Ok(input), filename: _) -> pipeline.run(input)
        Args(expression: Error(Nil), filename: Error(Nil)) -> repl()
        Args(expression: Error(Nil), filename: Ok(filename)) -> {
          case simplifile.read(filename) {
            Ok(input) -> pipeline.run(input)
            Error(error) ->
              error |> simplifile.describe_error |> io.println_error
          }
        }
      }
    }
  }
}

fn repl() -> Nil {
  case erlang.get_line("monkey> ") {
    Error(_) -> io.println("")
    Ok(line) -> {
      pipeline.run(line)
      repl()
    }
  }
}
