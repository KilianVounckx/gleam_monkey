import gleam/int
import gleam/list
import gleam/string

pub type Expression {
  Letrec(functions: List(LetrecFunction), body: Expression)
  Let(name: String, value: Expression, body: Expression)
  If(condition: Expression, consequence: Expression, alternative: Expression)
  Call(function: Expression, arguments: List(Expression))
  Index(collection: Expression, index: Expression)
  Infix(left: Expression, operator: InfixOperator, right: Expression)
  Prefix(operator: PrefixOperator, right: Expression)
  Variable(String)
  Function(parameters: List(String), body: Expression)
  Table(pairs: List(#(Expression, Expression)))
  List(values: List(Expression))
  String(String)
  Integer(Int)
  Boolean(Bool)
  Nil
}

pub type LetrecFunction {
  LetrecFunction(name: String, parameters: List(String), body: Expression)
}

pub type InfixOperator {
  Pipe
  Equal
  NotEqual
  Greater
  GreaterEqual
  Less
  LessEqual
  Concat
  Add
  Subtract
  Multiply
  Divide
}

pub type PrefixOperator {
  Negate
  Not
}

pub fn to_string(expression: Expression) -> String {
  case expression {
    Letrec(functions:, body:) -> {
      let functions =
        functions |> list.map(letrec_function_to_string) |> string.join(" and ")
      "let rec " <> functions <> " in " <> to_string(body)
    }
    Let(name:, value:, body:) -> {
      "let " <> name <> " = " <> to_string(value) <> " in " <> to_string(body)
    }
    If(condition:, consequence:, alternative:) -> {
      "if "
      <> to_string(condition)
      <> " then "
      <> to_string(consequence)
      <> " else "
      <> to_string(alternative)
    }
    Call(function:, arguments:) -> {
      to_string(function) <> "(" <> expressions_to_string(arguments) <> ")"
    }
    Index(collection:, index:) -> {
      to_string(collection) <> "[" <> to_string(index) <> "]"
    }
    Infix(left:, operator:, right:) -> {
      "("
      <> to_string(left)
      <> " "
      <> infix_to_string(operator)
      <> " "
      <> to_string(right)
      <> ")"
    }
    Prefix(operator:, right:) -> {
      "(" <> prefix_to_string(operator) <> to_string(right) <> ")"
    }
    Variable(name) -> name
    Function(parameters:, body:) -> {
      "fun("
      <> function_parameters_to_string(parameters)
      <> ") "
      <> to_string(body)
    }
    Table(pairs:) -> {
      "{"
      <> {
        pairs
        |> list.map(fn(pair) {
          let #(key, value) = pair
          to_string(key) <> ": " <> to_string(value)
        })
        |> string.join(", ")
      }
      <> "}"
    }
    List(values:) -> {
      "[" <> expressions_to_string(values) <> "]"
    }
    String(s) -> "\"" <> s <> "\""
    Integer(n) -> int.to_string(n)
    Boolean(True) -> "true"
    Boolean(False) -> "false"
    Nil -> "nil"
  }
}

pub fn infix_to_string(operator: InfixOperator) {
  case operator {
    Pipe -> "|>"
    Equal -> "=="
    NotEqual -> "!="
    Greater -> ">="
    GreaterEqual -> ">="
    Less -> "<"
    LessEqual -> "<="
    Concat -> "<>"
    Add -> "+"
    Subtract -> "-"
    Multiply -> "*"
    Divide -> "/"
  }
}

pub fn prefix_to_string(operator: PrefixOperator) {
  case operator {
    Negate -> "-"
    Not -> "!"
  }
}

fn expressions_to_string(expressions: List(Expression)) -> String {
  expressions |> list.map(to_string) |> string.join(", ")
}

fn letrec_function_to_string(function: LetrecFunction) -> String {
  function.name
  <> " = fun("
  <> function_parameters_to_string(function.parameters)
  <> ") "
  <> to_string(function.body)
}

fn function_parameters_to_string(parameters: List(String)) -> String {
  parameters |> string.join(", ")
}
