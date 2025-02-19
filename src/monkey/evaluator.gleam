import gleam/bool
import gleam/list
import gleam/result
import monkey/ast.{type Expression}
import monkey/value.{
  type Environment, type Value, Extend, ExtendRec, environment_lookup,
}

pub type Error =
  value.Error

pub fn eval(
  expression: Expression,
  environment: Environment,
) -> Result(Value, Error) {
  case expression {
    ast.Letrec(functions:, body:) -> {
      body |> eval(environment |> ExtendRec(functions:))
    }
    ast.Let(name:, value:, body:) -> {
      use value <- result.try(value |> eval(environment))
      body |> eval(environment |> Extend(name:, value:))
    }
    ast.If(condition:, consequence:, alternative:) -> {
      use condition <- result.try(condition |> eval(environment))
      case condition |> value.is_truthy {
        True -> consequence |> eval(environment)
        False -> alternative |> eval(environment)
      }
    }
    ast.Call(function:, arguments:) -> {
      eval_call(function, arguments, environment)
    }
    ast.Index(collection:, index:) -> {
      use collection <- result.try(collection |> eval(environment))
      use index <- result.try(index |> eval(environment))
      case collection, index {
        value.List(list), value.Integer(index) -> {
          list
          |> list_get_nth(index)
          |> result.map_error(fn(_) {
            value.IndexOutOfBounds(length: list.length(list), index:)
          })
        }
        value.Table(pairs), index -> {
          pairs
          |> list.key_find(index)
          |> result.map_error(fn(_) { value.KeyNotFound(key: index) })
        }
        _, _ -> Error(value.IndexTypeMismatch(collection:, index:))
      }
    }
    ast.Infix(left:, operator:, right:) -> {
      case operator {
        ast.Pipe -> {
          case right {
            ast.Call(function:, arguments:) -> {
              eval_call(function, [left, ..arguments], environment)
            }
            _ -> Error(value.PipeTypeMismatch(left:, right:))
          }
        }
        _ -> {
          use left <- result.try(left |> eval(environment))
          use right <- result.try(right |> eval(environment))
          case left, operator, right {
            _, ast.Equal, _ -> Ok(value.Boolean(left == right))
            _, ast.NotEqual, _ -> Ok(value.Boolean(left != right))
            value.Integer(left), ast.Greater, value.Integer(right) ->
              Ok(value.Boolean(left > right))
            value.Integer(left), ast.GreaterEqual, value.Integer(right) ->
              Ok(value.Boolean(left >= right))
            value.Integer(left), ast.Less, value.Integer(right) ->
              Ok(value.Boolean(left < right))
            value.Integer(left), ast.LessEqual, value.Integer(right) ->
              Ok(value.Boolean(left <= right))
            value.Integer(left), ast.Add, value.Integer(right) ->
              Ok(value.Integer(left + right))
            value.Integer(left), ast.Subtract, value.Integer(right) ->
              Ok(value.Integer(left - right))
            value.Integer(left), ast.Multiply, value.Integer(right) ->
              Ok(value.Integer(left * right))
            value.Integer(left), ast.Divide, value.Integer(right) ->
              Ok(value.Integer(left / right))
            value.String(left), ast.Concat, value.String(right) ->
              Ok(value.String(left <> right))
            _, _, _ -> Error(value.InfixTypeMismatch(left:, operator:, right:))
          }
        }
      }
    }
    ast.Prefix(operator:, right:) -> {
      use right <- result.try(right |> eval(environment))
      case operator {
        ast.Not ->
          right |> value.is_truthy |> bool.negate |> value.Boolean |> Ok
        ast.Negate -> {
          case right {
            value.Integer(n) -> Ok(value.Integer(-n))
            _ -> Error(value.PrefixTypeMismatch(operator:, right:))
          }
        }
      }
    }
    ast.Variable(name) -> {
      environment
      |> environment_lookup(name)
    }
    ast.Function(parameters:, body:) ->
      Ok(value.Function(parameters:, body:, environment:))
    ast.Table(pairs:) -> {
      use pairs <- result.try(pairs |> eval_pairs(environment))
      Ok(value.Table(pairs))
    }
    ast.List(values:) -> {
      use values <- result.try(values |> eval_expressions(environment))
      Ok(value.List(values))
    }
    ast.String(s) -> Ok(value.String(s))
    ast.Integer(n) -> Ok(value.Integer(n))
    ast.Boolean(b) -> Ok(value.Boolean(b))
    ast.Nil -> Ok(value.Nil)
  }
}

fn eval_call(
  function: Expression,
  arguments: List(Expression),
  environment: Environment,
) -> Result(Value, Error) {
  use function <- result.try(function |> eval(environment))
  use arguments <- result.try(arguments |> eval_expressions(environment))
  case function {
    value.Function(parameters:, body:, environment:) -> {
      let num_parameters = parameters |> list.length
      let num_arguments = arguments |> list.length
      case num_parameters == num_arguments {
        True -> {
          let environment =
            parameters
            |> list.zip(arguments)
            |> list.fold(environment, fn(environment, entry) {
              let #(parameter, argument) = entry
              environment |> Extend(name: parameter, value: argument)
            })
          body |> eval(environment)
        }
        False ->
          Error(value.ArityMismatch(got: num_arguments, want: num_parameters))
      }
    }
    value.Builtin(name: _, function:) -> {
      function(arguments)
    }
    _ -> Error(value.NotAFunction(value: function))
  }
}

fn eval_pairs(
  pairs: List(#(Expression, Expression)),
  environment: Environment,
) -> Result(List(#(Value, Value)), Error) {
  do_eval_pairs([], pairs, environment) |> result.map(list.reverse)
}

fn do_eval_pairs(
  value_pairs: List(#(Value, Value)),
  expression_pairs: List(#(Expression, Expression)),
  environment: Environment,
) -> Result(List(#(Value, Value)), Error) {
  case expression_pairs {
    [] -> Ok(value_pairs)
    [#(key, value), ..expression_pairs] -> {
      use key <- result.try(key |> eval(environment))
      use value <- result.try(value |> eval(environment))
      let value_pairs = [#(key, value), ..value_pairs]
      value_pairs |> do_eval_pairs(expression_pairs, environment)
    }
  }
}

fn eval_expressions(
  expressions: List(Expression),
  environment: Environment,
) -> Result(List(Value), Error) {
  do_eval_expressions([], expressions, environment) |> result.map(list.reverse)
}

fn do_eval_expressions(
  values: List(Value),
  expressions: List(Expression),
  environment: Environment,
) -> Result(List(Value), Error) {
  case expressions {
    [] -> Ok(values)
    [expression, ..expressions] -> {
      use value <- result.try(expression |> eval(environment))
      let values = [value, ..values]
      values |> do_eval_expressions(expressions, environment)
    }
  }
}

fn list_get_nth(list: List(a), index: Int) -> Result(a, Nil) {
  case list, index {
    [], _ -> Error(Nil)
    [first, ..], 0 -> Ok(first)
    [_, ..rest], index -> list_get_nth(rest, index - 1)
  }
}
