import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import monkey/ast.{type Expression}
import monkey/value.{
  type Environment, type Value, Extend, ExtendRec, environment_lookup,
}

pub type Error {
  InfixTypeMismatch(left: Value, operator: ast.InfixOperator, right: Value)
  PrefixTypeMismatch(operator: ast.PrefixOperator, right: Value)
  VariableNotFound(name: String)
  NotAFunction(value: Value)
  ArityMismatch(got: Int, want: Int)
}

pub fn error_to_string(error: Error) -> String {
  case error {
    InfixTypeMismatch(left:, operator:, right:) -> {
      "type mismatch: "
      <> value.to_string(left)
      <> " "
      <> ast.infix_to_string(operator)
      <> " "
      <> value.to_string(right)
    }
    PrefixTypeMismatch(operator:, right:) -> {
      "type mismatch: "
      <> ast.prefix_to_string(operator)
      <> value.to_string(right)
    }
    VariableNotFound(name:) -> {
      "variable not found: " <> name
    }
    NotAFunction(value:) -> {
      "not a function: " <> value.to_string(value)
    }
    ArityMismatch(got:, want:) -> {
      "arity mismatch: expected "
      <> int.to_string(want)
      <> ", got "
      <> int.to_string(got)
    }
  }
}

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
              Error(ArityMismatch(got: num_arguments, want: num_parameters))
          }
        }
        _ -> Error(NotAFunction(value: function))
      }
    }
    ast.Infix(left:, operator:, right:) -> {
      use left <- result.try(left |> eval(environment))
      use right <- result.try(right |> eval(environment))
      case operator {
        ast.Equal -> Ok(value.Boolean(left == right))
        ast.NotEqual -> Ok(value.Boolean(left != right))
        _ -> {
          case left, right {
            value.Integer(left), value.Integer(right) -> {
              case operator {
                ast.Greater -> Ok(value.Boolean(left > right))
                ast.GreaterEqual -> Ok(value.Boolean(left >= right))
                ast.Less -> Ok(value.Boolean(left < right))
                ast.LessEqual -> Ok(value.Boolean(left <= right))
                ast.Add -> Ok(value.Integer(left + right))
                ast.Subtract -> Ok(value.Integer(left - right))
                ast.Multiply -> Ok(value.Integer(left * right))
                ast.Divide -> Ok(value.Integer(left / right))
                ast.Equal | ast.NotEqual -> panic as "unreachable infix eval"
              }
            }
            _, _ -> Error(InfixTypeMismatch(left:, operator:, right:))
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
            _ -> Error(PrefixTypeMismatch(operator:, right:))
          }
        }
      }
    }
    ast.Variable(name) -> {
      environment
      |> environment_lookup(name)
      |> result.map_error(fn(_) { VariableNotFound(name) })
    }
    ast.Function(parameters:, body:) ->
      Ok(value.Function(parameters:, body:, environment:))
    ast.Integer(n) -> Ok(value.Integer(n))
    ast.Boolean(b) -> Ok(value.Boolean(b))
    ast.Nil -> Ok(value.Nil)
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
