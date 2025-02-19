import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import monkey/ast
import monkey/evaluator
import monkey/lexer
import monkey/parser
import monkey/value.{type Value, Empty}

pub fn eval_test() {
  pipeline(
    "let rec even = fun(n) if n == 0 then true else odd(n - 1)
and odd = fun(n) if n == 0 then false else even(n - 1) in
even(10)",
  )
  |> should.equal(value.Boolean(True))
  pipeline(
    "let rec even = fun(n) if n == 0 then true else odd(n - 1)
and odd = fun(n) if n == 0 then false else even(n - 1) in
odd(10)",
  )
  |> should.equal(value.Boolean(False))
  pipeline(
    "let rec fact = fun(n) if n <= 0 then 1 else n * fact(n - 1) in fact(5)",
  )
  |> should.equal(value.Integer(120))
  pipeline(
    "let adder = fun(x) fun(y) x + y in let add_two = adder(2) in add_two(2)",
  )
  |> should.equal(value.Integer(4))
  pipeline("let identity = fun(x) x in identity(5)")
  |> should.equal(value.Integer(5))
  pipeline("let double = fun(x) x * 2 in double(5)")
  |> should.equal(value.Integer(10))
  pipeline("let sub = fun(x, y) x - y in sub(5, 10)")
  |> should.equal(value.Integer(-5))
  pipeline("let add = fun(x, y) x + y in add(5, 5)")
  |> should.equal(value.Integer(10))
  pipeline("let add = fun(x, y) x + y in add(5 + 5, add(5, 5))")
  |> should.equal(value.Integer(20))
  pipeline("(fun(x) x)(5)") |> should.equal(value.Integer(5))
  pipeline("fun(x, y) x + y")
  |> should.equal(value.Function(
    parameters: ["x", "y"],
    body: ast.Infix(
      left: ast.Variable("x"),
      operator: ast.Add,
      right: ast.Variable("y"),
    ),
    environment: Empty,
  ))
  pipeline("let a = 5 in a") |> should.equal(value.Integer(5))
  pipeline("let a = 5 * 5 in a") |> should.equal(value.Integer(25))
  pipeline("let a = 5 in let b = a in b") |> should.equal(value.Integer(5))
  pipeline("let a = 5 in let b = a in let c = a + b + 5 in c")
  |> should.equal(value.Integer(15))
  pipeline("if true then 10 else nil") |> should.equal(value.Integer(10))
  pipeline("if false then 10 else nil") |> should.equal(value.Nil)
  pipeline("if 1 then 10 else nil") |> should.equal(value.Integer(10))
  pipeline("if 1 < 2 then 10 else nil") |> should.equal(value.Integer(10))
  pipeline("if 1 > 2 then 10 else nil") |> should.equal(value.Nil)
  pipeline("if 1 > 2 then 10 else 20") |> should.equal(value.Integer(20))
  pipeline("if 1 < 2 then 10 else 20") |> should.equal(value.Integer(10))
  pipeline("true == true") |> should.equal(value.Boolean(True))
  pipeline("false == false") |> should.equal(value.Boolean(True))
  pipeline("true == false") |> should.equal(value.Boolean(False))
  pipeline("true != false") |> should.equal(value.Boolean(True))
  pipeline("false != true") |> should.equal(value.Boolean(True))
  pipeline("(1 < 2) == true") |> should.equal(value.Boolean(True))
  pipeline("(1 < 2) == false") |> should.equal(value.Boolean(False))
  pipeline("(1 > 2) == true") |> should.equal(value.Boolean(False))
  pipeline("(1 > 2) == false") |> should.equal(value.Boolean(True))
  pipeline("5") |> should.equal(value.Integer(5))
  pipeline("10") |> should.equal(value.Integer(10))
  pipeline("-5") |> should.equal(value.Integer(-5))
  pipeline("-10") |> should.equal(value.Integer(-10))
  pipeline("5 + 5 + 5 + 5 - 10") |> should.equal(value.Integer(10))
  pipeline("2 * 2 * 2 * 2 * 2") |> should.equal(value.Integer(32))
  pipeline("-50 + 100 + -50") |> should.equal(value.Integer(0))
  pipeline("5 * 2 + 10") |> should.equal(value.Integer(20))
  pipeline("5 + 2 * 10") |> should.equal(value.Integer(25))
  pipeline("20 + 2 * -10") |> should.equal(value.Integer(0))
  pipeline("50 / 2 * 2 + 10") |> should.equal(value.Integer(60))
  pipeline("2 * (5 + 10)") |> should.equal(value.Integer(30))
  pipeline("3 * 3 * 3 + 10") |> should.equal(value.Integer(37))
  pipeline("3 * (3 * 3) + 10") |> should.equal(value.Integer(37))
  pipeline("(5 + 10 * 2 + 15 / 3) * 2 + -10") |> should.equal(value.Integer(50))
  pipeline("-5") |> should.equal(value.Integer(-5))
  pipeline("!!true") |> should.equal(value.Boolean(True))
  pipeline("!!false") |> should.equal(value.Boolean(False))
  pipeline("!!nil") |> should.equal(value.Boolean(False))
  pipeline("!!0") |> should.equal(value.Boolean(True))
  pipeline("!!5") |> should.equal(value.Boolean(True))
  pipeline("!true") |> should.equal(value.Boolean(False))
  pipeline("!false") |> should.equal(value.Boolean(True))
  pipeline("!nil") |> should.equal(value.Boolean(True))
  pipeline("!0") |> should.equal(value.Boolean(False))
  pipeline("!5") |> should.equal(value.Boolean(False))
  pipeline("42") |> should.equal(value.Integer(42))
  pipeline("true") |> should.equal(value.Boolean(True))
  pipeline("false") |> should.equal(value.Boolean(False))
  pipeline("nil") |> should.equal(value.Nil)
}

pub fn eval_error_test() {
  pipeline_error("foobar")
  |> should.equal(evaluator.VariableNotFound(name: "foobar"))
  pipeline_error("5 + true")
  |> should.equal(evaluator.InfixTypeMismatch(
    left: value.Integer(5),
    operator: ast.Add,
    right: value.Boolean(True),
  ))
  pipeline_error("-true")
  |> should.equal(evaluator.PrefixTypeMismatch(
    operator: ast.Negate,
    right: value.Boolean(True),
  ))
}

fn pipeline_error(input: String) -> evaluator.Error {
  input
  |> lexer.lex
  |> result.map_error(fn(errors) {
    errors |> list.map(lexer.error_to_string) |> string.join("\n")
  })
  |> should.be_ok
  |> parser.parse
  |> result.map_error(parser.error_to_string)
  |> should.be_ok
  |> evaluator.eval(Empty)
  |> result.map(value.to_string)
  |> should.be_error
}

fn pipeline(input: String) -> Value {
  input
  |> lexer.lex
  |> result.map_error(fn(errors) {
    errors |> list.map(lexer.error_to_string) |> string.join("\n")
  })
  |> should.be_ok
  |> parser.parse
  |> result.map_error(parser.error_to_string)
  |> should.be_ok
  |> evaluator.eval(Empty)
  |> result.map_error(evaluator.error_to_string)
  |> should.be_ok
}
