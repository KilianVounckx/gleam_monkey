import gleam/int
import gleam/list
import gleam/string
import monkey/ast.{type Expression}

pub type Error {
  StringLengthTypeMismatch(got: Value)
  InfixTypeMismatch(left: Value, operator: ast.InfixOperator, right: Value)
  PrefixTypeMismatch(operator: ast.PrefixOperator, right: Value)
  VariableNotFound(name: String)
  NotAFunction(value: Value)
  ArityMismatch(got: Int, want: Int)
}

pub type Value {
  Function(parameters: List(String), body: Expression, environment: Environment)
  Builtin(name: String, function: fn(List(Value)) -> Result(Value, Error))
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

pub const initial_environment = Extend(
  Empty,
  "string_length",
  Builtin(name: "string_length", function: string_length),
)

pub fn environment_lookup(
  environment: Environment,
  name,
) -> Result(Value, Error) {
  case environment {
    Empty -> Error(VariableNotFound(name:))
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
    Builtin(name:, function: _) -> "<builtin function '" <> name <> "'>"
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

pub fn error_to_string(error: Error) -> String {
  case error {
    StringLengthTypeMismatch(got:) -> {
      "type mismatch: string_length(" <> to_string(got) <> ")"
    }
    InfixTypeMismatch(left:, operator:, right:) -> {
      "type mismatch: "
      <> to_string(left)
      <> " "
      <> ast.infix_to_string(operator)
      <> " "
      <> to_string(right)
    }
    PrefixTypeMismatch(operator:, right:) -> {
      "type mismatch: " <> ast.prefix_to_string(operator) <> to_string(right)
    }
    VariableNotFound(name:) -> {
      "variable not found: " <> name
    }
    NotAFunction(value:) -> {
      "not a function: " <> to_string(value)
    }
    ArityMismatch(got:, want:) -> {
      "arity mismatch: expected "
      <> int.to_string(want)
      <> ", got "
      <> int.to_string(got)
    }
  }
}

fn string_length(values: List(Value)) -> Result(Value, Error) {
  case values {
    [String(s)] -> Ok(Integer(string.length(s)))
    [value] -> Error(StringLengthTypeMismatch(got: value))
    _ -> Error(ArityMismatch(got: list.length(values), want: 1))
  }
}
