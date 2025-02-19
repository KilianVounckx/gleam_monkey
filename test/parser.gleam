import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import monkey/ast.{type Expression}
import monkey/lexer
import monkey/parser

pub fn parse_test() {
  pipeline("let rec foo = fun() true and bar = fun(x, y, z) false in nil")
  |> should.equal(ast.Letrec(
    functions: [
      ast.LetrecFunction(name: "foo", parameters: [], body: ast.Boolean(True)),
      ast.LetrecFunction(
        name: "bar",
        parameters: ["x", "y", "z"],
        body: ast.Boolean(False),
      ),
    ],
    body: ast.Nil,
  ))
  pipeline("let x = true in false")
  |> should.equal(ast.Let(
    name: "x",
    value: ast.Boolean(True),
    body: ast.Boolean(False),
  ))
  pipeline("if nil then true else false")
  |> should.equal(ast.If(
    condition: ast.Nil,
    consequence: ast.Boolean(True),
    alternative: ast.Boolean(False),
  ))
  pipeline("add(1, 2 * 3, 4 + 5)")
  |> should.equal(
    ast.Call(function: ast.Variable("add"), arguments: [
      ast.Integer(1),
      ast.Infix(
        left: ast.Integer(2),
        operator: ast.Multiply,
        right: ast.Integer(3),
      ),
      ast.Infix(left: ast.Integer(4), operator: ast.Add, right: ast.Integer(5)),
    ]),
  )
  pipeline("foo[bar]")
  |> should.equal(ast.Index(
    collection: ast.Variable("foo"),
    index: ast.Variable("bar"),
  ))
  pipeline("(1 + 2) * 3")
  |> should.equal(ast.Infix(
    left: ast.Infix(
      left: ast.Integer(1),
      operator: ast.Add,
      right: ast.Integer(2),
    ),
    operator: ast.Multiply,
    right: ast.Integer(3),
  ))
  pipeline("1 * (2 + 3)")
  |> should.equal(ast.Infix(
    left: ast.Integer(1),
    operator: ast.Multiply,
    right: ast.Infix(
      left: ast.Integer(2),
      operator: ast.Add,
      right: ast.Integer(3),
    ),
  ))
  pipeline("1 + 2 * 3")
  |> should.equal(ast.Infix(
    left: ast.Integer(1),
    operator: ast.Add,
    right: ast.Infix(
      left: ast.Integer(2),
      operator: ast.Multiply,
      right: ast.Integer(3),
    ),
  ))
  pipeline("1 * 2 + 3")
  |> should.equal(ast.Infix(
    left: ast.Infix(
      left: ast.Integer(1),
      operator: ast.Multiply,
      right: ast.Integer(2),
    ),
    operator: ast.Add,
    right: ast.Integer(3),
  ))
  pipeline("1 + 2 + 3")
  |> should.equal(ast.Infix(
    left: ast.Infix(
      left: ast.Integer(1),
      operator: ast.Add,
      right: ast.Integer(2),
    ),
    operator: ast.Add,
    right: ast.Integer(3),
  ))
  pipeline("5 == 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.Equal,
    right: ast.Integer(5),
  ))
  pipeline("5 != 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.NotEqual,
    right: ast.Integer(5),
  ))
  pipeline("5 > 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.Greater,
    right: ast.Integer(5),
  ))
  pipeline("5 >= 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.GreaterEqual,
    right: ast.Integer(5),
  ))
  pipeline("5 < 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.Less,
    right: ast.Integer(5),
  ))
  pipeline("5 <= 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.LessEqual,
    right: ast.Integer(5),
  ))
  pipeline("\"hi\" <> \"no\"")
  |> should.equal(ast.Infix(
    left: ast.String("hi"),
    operator: ast.Concat,
    right: ast.String("no"),
  ))
  pipeline("5 - 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.Subtract,
    right: ast.Integer(5),
  ))
  pipeline("5 + 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.Add,
    right: ast.Integer(5),
  ))
  pipeline("5 * 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.Multiply,
    right: ast.Integer(5),
  ))
  pipeline("5 / 5")
  |> should.equal(ast.Infix(
    left: ast.Integer(5),
    operator: ast.Divide,
    right: ast.Integer(5),
  ))
  pipeline("-42")
  |> should.equal(ast.Prefix(operator: ast.Negate, right: ast.Integer(42)))
  pipeline("!true")
  |> should.equal(ast.Prefix(operator: ast.Not, right: ast.Boolean(True)))
  pipeline("foobar") |> should.equal(ast.Variable("foobar"))
  pipeline("fun() nil")
  |> should.equal(ast.Function(parameters: [], body: ast.Nil))
  pipeline("fun(x) nil")
  |> should.equal(ast.Function(parameters: ["x"], body: ast.Nil))
  pipeline("fun(x, y, z) nil")
  |> should.equal(ast.Function(parameters: ["x", "y", "z"], body: ast.Nil))
  pipeline("fun(x, y) x + y")
  |> should.equal(ast.Function(
    parameters: ["x", "y"],
    body: ast.Infix(
      left: ast.Variable("x"),
      operator: ast.Add,
      right: ast.Variable("y"),
    ),
  ))
  pipeline("[1, 2, 3]")
  |> should.equal(ast.List([ast.Integer(1), ast.Integer(2), ast.Integer(3)]))
  pipeline("foo.bar")
  |> should.equal(ast.Index(
    collection: ast.Variable("foo"),
    index: ast.String("bar"),
  ))
  pipeline("\"hi there\"") |> should.equal(ast.String("hi there"))
  pipeline("42") |> should.equal(ast.Integer(42))
  pipeline("true") |> should.equal(ast.Boolean(True))
  pipeline("false") |> should.equal(ast.Boolean(False))
  pipeline("nil") |> should.equal(ast.Nil)
}

fn pipeline(input: String) -> Expression {
  input
  |> lexer.lex
  |> result.map_error(fn(errors) {
    errors |> list.map(lexer.error_to_string) |> string.join("\n")
  })
  |> should.be_ok
  |> parser.parse
  |> result.map_error(parser.error_to_string)
  |> should.be_ok
}
