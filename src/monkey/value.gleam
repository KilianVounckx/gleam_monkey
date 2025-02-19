import gleam/int
import gleam/list
import monkey/ast.{type Expression}

pub type Value {
  Function(parameters: List(String), body: Expression, environment: Environment)
  String(String)
  Integer(Int)
  Boolean(Bool)
  Nil
}

pub type Environment {
  Empty
  Extend(inner: Environment, name: String, value: Value)
  ExtendRec(inner: Environment, functions: List(ast.LetrecFunction))
}

pub type VariableNotFound {
  VariableNotFound
}

pub fn environment_lookup(
  environment: Environment,
  name,
) -> Result(Value, VariableNotFound) {
  case environment {
    Empty -> Error(VariableNotFound)
    Extend(inner:, name: entry_name, value:) -> {
      case name == entry_name {
        True -> Ok(value)
        False -> inner |> environment_lookup(name)
      }
    }
    ExtendRec(inner:, functions:) -> {
      case
        functions
        |> list.find(fn(function) { function.name == name })
      {
        Ok(function) ->
          Ok(Function(
            parameters: function.parameters,
            body: function.body,
            environment:,
          ))
        Error(_) -> inner |> environment_lookup(name)
      }
    }
  }
}

pub fn to_string(value: Value) -> String {
  case value {
    Function(_, _, _) -> "<function>"
    String(s) -> "\"" <> s <> "\""
    Integer(n) -> int.to_string(n)
    Boolean(True) -> "true"
    Boolean(False) -> "false"
    Nil -> "nil"
  }
}

pub fn is_truthy(value: Value) -> Bool {
  case value {
    Nil -> False
    Boolean(b) -> b
    _ -> True
  }
}
