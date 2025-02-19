import act/state
import gleam/list
import gleam/result
import monkey/ast.{type Expression}
import monkey/token.{type Token}

import act.{type ResultAction}

pub type Error {
  ExpectedEof(got: Token)
  ExpectedExpression(got: Token)
  ExpectedIdentifier(got: Token)
  Expected(got: Token, want: Token)
}

pub fn error_to_string(error: Error) -> String {
  case error {
    ExpectedEof(got:) -> "Expected end of file, got " <> token.to_string(got)
    ExpectedExpression(got:) ->
      "Expected an expression, got " <> token.to_string(got)
    ExpectedIdentifier(got:) ->
      "Expected an identifier, got " <> token.to_string(got)
    Expected(got:, want:) ->
      "Expected " <> token.to_string(want) <> ", got " <> token.to_string(got)
  }
}

pub fn parse(tokens: List(Token)) -> Result(Expression, Error) {
  let parser = Parser(tokens:)
  let #(parser, parse_result) =
    {
      use expression <- act.try(parse_expression(precedence_lowest))
      use _ <- act.try(advance())
      act.ok(expression)
    }
    |> act.run(parser)
  use ast <- result.try(parse_result)
  case parser.tokens {
    [token.Eof] -> Ok(ast)
    [] -> Ok(ast)
    [got, ..] -> Error(ExpectedEof(got:))
  }
}

type Parser {
  Parser(tokens: List(Token))
}

fn parse_expression(precedence: Int) -> ResultAction(Expression, Error, Parser) {
  use current <- act.try(current_token())
  use left <- act.try(prefix(current))
  do_parse_expression(left, precedence)
}

fn do_parse_expression(
  left: Expression,
  precedence: Int,
) -> ResultAction(Expression, Error, Parser) {
  use peek <- act.try(peek_token())
  case precedence < precedence_from_token(peek) {
    True -> {
      use left <- act.try(infix(peek, left))
      do_parse_expression(left, precedence)
    }
    False -> act.ok(left)
  }
}

fn infix(
  token: Token,
  left: Expression,
) -> ResultAction(Expression, Error, Parser) {
  case token {
    token.LeftParen -> {
      use _ <- act.try(advance())
      parse_call(left)
    }
    token.LeftBracket -> {
      use _ <- act.try(advance())
      parse_index(left)
    }
    token.Dot -> {
      use _ <- act.try(advance())
      parse_field_access(left)
    }
    token.BarGreater
    | token.EqualEqual
    | token.BangEqual
    | token.Greater
    | token.GreaterEqual
    | token.Less
    | token.LessEqual
    | token.LessGreater
    | token.Plus
    | token.Minus
    | token.Star
    | token.Slash -> {
      use _ <- act.try(advance())
      parse_infix(left)
    }
    _ -> act.ok(left)
  }
}

fn prefix(token: Token) -> ResultAction(Expression, Error, Parser) {
  case token {
    token.Let -> parse_let()
    token.If -> parse_if()
    token.Bang | token.Minus -> parse_prefix()
    token.Identifier(_) -> parse_identifier()
    token.Fun -> parse_function()
    token.LeftBrace -> parse_table()
    token.LeftBracket -> parse_list()
    token.String(_) -> parse_string()
    token.Integer(_) -> parse_integer()
    token.True | token.False -> parse_boolean()
    token.Nil -> parse_nil()
    token.LeftParen -> parse_group()
    _ -> act.error(ExpectedExpression(got: token))
  }
}

fn parse_let() -> ResultAction(Expression, Error, Parser) {
  use peek <- act.try(peek_token())
  case peek {
    token.Rec -> parse_letrec()
    _ -> {
      use name <- act.try(expect_peek_identifier())
      use _ <- act.try(expect_peek_token(token.Equal))
      use _ <- act.try(advance())
      use value <- act.try(parse_expression(precedence_lowest))
      use _ <- act.try(expect_peek_token(token.In))
      use _ <- act.try(advance())
      use body <- act.try(parse_expression(precedence_lowest))
      act.ok(ast.Let(name:, value:, body:))
    }
  }
}

fn parse_letrec() -> ResultAction(Expression, Error, Parser) {
  use _ <- act.try(advance())
  use functions <- act.try(parse_letrec_functions([]))
  let functions = functions |> list.reverse
  use _ <- act.try(expect_peek_token(token.In))
  use _ <- act.try(advance())
  use body <- act.try(parse_expression(precedence_lowest))
  act.ok(ast.Letrec(functions:, body:))
}

fn parse_letrec_functions(
  functions: List(ast.LetrecFunction),
) -> ResultAction(List(ast.LetrecFunction), Error, Parser) {
  use name <- act.try(expect_peek_identifier())
  use _ <- act.try(expect_peek_token(token.Equal))
  use _ <- act.try(expect_peek_token(token.Fun))
  use _ <- act.try(expect_peek_token(token.LeftParen))
  use parameters <- act.try(parse_function_parameters())
  use _ <- act.try(advance())
  use body <- act.try(parse_expression(precedence_lowest))
  let function = ast.LetrecFunction(name:, parameters:, body:)
  let functions = [function, ..functions]

  use peek <- act.try(peek_token())
  case peek {
    token.And -> {
      use _ <- act.try(advance())
      parse_letrec_functions(functions)
    }
    _ -> act.ok(functions)
  }
}

fn parse_if() -> ResultAction(Expression, Error, Parser) {
  use _ <- act.try(advance())
  use condition <- act.try(parse_expression(precedence_lowest))
  use _ <- act.try(expect_peek_token(token.Then))
  use _ <- act.try(advance())
  use consequence <- act.try(parse_expression(precedence_lowest))
  use _ <- act.try(expect_peek_token(token.Else))
  use _ <- act.try(advance())
  use alternative <- act.try(parse_expression(precedence_lowest))
  act.ok(ast.If(condition:, consequence:, alternative:))
}

fn parse_call(function: Expression) -> ResultAction(Expression, Error, Parser) {
  use arguments <- act.try(parse_call_arguments())
  act.ok(ast.Call(function:, arguments:))
}

fn parse_call_arguments() -> ResultAction(List(Expression), Error, Parser) {
  parse_expressions(token.RightParen)
}

fn parse_index(
  collection: Expression,
) -> ResultAction(Expression, Error, Parser) {
  use _ <- act.try(advance())
  use index <- act.try(parse_expression(precedence_lowest))
  use _ <- act.try(expect_peek_token(token.RightBracket))
  act.ok(ast.Index(collection:, index:))
}

fn parse_field_access(
  collection: Expression,
) -> ResultAction(Expression, Error, Parser) {
  use index <- act.try(expect_peek_identifier())
  let index = ast.String(index)
  act.ok(ast.Index(collection:, index:))
}

fn parse_infix(left: Expression) -> ResultAction(Expression, Error, Parser) {
  use current <- act.try(current_token())
  let operator = case current {
    token.BarGreater -> ast.Pipe
    token.EqualEqual -> ast.Equal
    token.BangEqual -> ast.NotEqual
    token.Greater -> ast.Greater
    token.GreaterEqual -> ast.GreaterEqual
    token.Less -> ast.Less
    token.LessEqual -> ast.LessEqual
    token.LessGreater -> ast.Concat
    token.Plus -> ast.Add
    token.Minus -> ast.Subtract
    token.Star -> ast.Multiply
    token.Slash -> ast.Divide
    _ -> panic as "unreachable in infix"
  }
  let precedence = precedence_from_token(current)
  use _ <- act.try(advance())
  use right <- act.try(parse_expression(precedence))
  act.ok(ast.Infix(left:, operator:, right:))
}

fn parse_prefix() -> ResultAction(Expression, Error, Parser) {
  use current <- act.try(current_token())
  let operator = case current {
    token.Bang -> ast.Not
    token.Minus -> ast.Negate
    _ -> panic as "unreachable in prefix"
  }
  use _ <- act.try(advance())
  use right <- act.try(parse_expression(precedence_prefix))
  act.ok(ast.Prefix(operator:, right:))
}

fn parse_identifier() -> ResultAction(Expression, Error, Parser) {
  use current <- act.try(current_token())
  case current {
    token.Identifier(n) -> act.ok(ast.Variable(n))
    _ -> panic as "unreachable in identifier"
  }
}

fn parse_function() -> ResultAction(Expression, Error, Parser) {
  use _ <- act.try(expect_peek_token(token.LeftParen))
  use parameters <- act.try(parse_function_parameters())
  use _ <- act.try(advance())
  use body <- act.try(parse_expression(precedence_lowest))
  act.ok(ast.Function(parameters:, body:))
}

fn parse_function_parameters() -> ResultAction(List(String), Error, Parser) {
  use peek <- act.try(peek_token())
  case peek {
    token.RightParen -> {
      use _ <- act.try(advance())
      act.ok([])
    }
    _ -> {
      use parameters <- act.try(do_parse_function_parameters([]))
      let parameters = parameters |> list.reverse
      use _ <- act.try(expect_peek_token(token.RightParen))
      act.ok(parameters)
    }
  }
}

fn do_parse_function_parameters(
  parameters: List(String),
) -> ResultAction(List(String), Error, Parser) {
  use parameter <- act.try(expect_peek_identifier())
  let parameters = [parameter, ..parameters]
  use peek <- act.try(peek_token())
  case peek {
    token.Comma -> {
      use _ <- act.try(advance())
      do_parse_function_parameters(parameters)
    }
    _ -> act.ok(parameters)
  }
}

fn parse_string() -> ResultAction(Expression, Error, Parser) {
  use current <- act.try(current_token())
  case current {
    token.String(s) -> act.ok(ast.String(s))
    _ -> panic as "unreachable in string"
  }
}

fn parse_table() -> ResultAction(Expression, Error, Parser) {
  use pairs <- act.try(parse_table_pairs())
  act.ok(ast.Table(pairs:))
}

fn parse_table_pairs() -> ResultAction(
  List(#(Expression, Expression)),
  Error,
  Parser,
) {
  use peek <- act.try(peek_token())
  case peek == token.RightBrace {
    True -> {
      use _ <- act.try(advance())
      act.ok([])
    }
    False -> {
      use pairs <- act.try(do_parse_table_pairs([]))
      let pairs = pairs |> list.reverse
      use _ <- act.try(expect_peek_token(token.RightBrace))
      act.ok(pairs)
    }
  }
}

fn do_parse_table_pairs(
  pairs: List(#(Expression, Expression)),
) -> ResultAction(List(#(Expression, Expression)), Error, Parser) {
  use _ <- act.try(advance())
  use key <- act.try(parse_expression(precedence_lowest))
  use _ <- act.try(expect_peek_token(token.Colon))
  use _ <- act.try(advance())
  use value <- act.try(parse_expression(precedence_lowest))
  let pairs = [#(key, value), ..pairs]
  use peek <- act.try(peek_token())
  case peek {
    token.Comma -> {
      use _ <- act.try(advance())
      do_parse_table_pairs(pairs)
    }
    _ -> act.ok(pairs)
  }
}

fn parse_list() -> ResultAction(Expression, Error, Parser) {
  use expressions <- act.try(parse_expressions(token.RightBracket))
  act.ok(ast.List(expressions))
}

fn parse_integer() -> ResultAction(Expression, Error, Parser) {
  use current <- act.try(current_token())
  case current {
    token.Integer(n) -> act.ok(ast.Integer(n))
    _ -> panic as "unreachable in integer"
  }
}

fn parse_boolean() -> ResultAction(Expression, Error, Parser) {
  use current <- act.try(current_token())
  case current {
    token.True -> act.ok(ast.Boolean(True))
    token.False -> act.ok(ast.Boolean(False))
    _ -> panic as "unreachable in boolean"
  }
}

fn parse_nil() -> ResultAction(Expression, Error, Parser) {
  act.ok(ast.Nil)
}

fn parse_group() -> ResultAction(Expression, Error, Parser) {
  use _ <- act.try(advance())
  use expression <- act.try(parse_expression(precedence_lowest))
  use _ <- act.try(expect_peek_token(token.RightParen))
  act.ok(expression)
}

fn parse_expressions(
  end_token: Token,
) -> ResultAction(List(Expression), Error, Parser) {
  use peek <- act.try(peek_token())
  case peek == end_token {
    True -> {
      use _ <- act.try(advance())
      act.ok([])
    }
    False -> {
      use arguments <- act.try(do_parse_expressions([]))
      let arguments = arguments |> list.reverse
      use _ <- act.try(expect_peek_token(end_token))
      act.ok(arguments)
    }
  }
}

fn do_parse_expressions(
  arguments: List(Expression),
) -> ResultAction(List(Expression), Error, Parser) {
  use _ <- act.try(advance())
  use argument <- act.try(parse_expression(precedence_lowest))
  let arguments = [argument, ..arguments]
  use peek <- act.try(peek_token())
  case peek {
    token.Comma -> {
      use _ <- act.try(advance())
      do_parse_expressions(arguments)
    }
    _ -> act.ok(arguments)
  }
}

fn advance() -> ResultAction(Nil, Error, Parser) {
  use parser: Parser <- state.get
  use <- state.set(Parser(tokens: parser.tokens |> list.drop(1)))
  act.ok(Nil)
}

fn expect_peek_token(want: Token) -> ResultAction(Nil, Error, Parser) {
  use got <- act.try(peek_token())
  case got == want {
    True -> {
      use _ <- act.try(advance())
      act.ok(Nil)
    }
    _ -> {
      act.error(Expected(got:, want:))
    }
  }
}

fn expect_peek_identifier() -> ResultAction(String, Error, Parser) {
  use peek <- act.try(peek_token())
  case peek {
    token.Identifier(name) -> {
      use _ <- act.try(advance())
      act.ok(name)
    }
    _ -> {
      act.error(ExpectedIdentifier(got: peek))
    }
  }
}

fn current_token() -> ResultAction(Token, Error, Parser) {
  use parser: Parser <- state.get()
  parser.tokens
  |> list.first
  |> result.unwrap(token.Eof)
  |> act.ok
}

fn peek_token() -> ResultAction(Token, Error, Parser) {
  use parser: Parser <- state.get
  case parser.tokens {
    [] | [_] -> token.Eof
    [_, token, ..] -> token
  }
  |> act.ok
}

fn precedence_from_token(token: Token) -> Int {
  case token {
    token.BarGreater -> precedence_pipe
    token.EqualEqual | token.BangEqual -> precedence_equality
    token.Greater | token.GreaterEqual | token.Less | token.LessEqual ->
      precedence_comparison
    token.LessGreater -> precedence_concat
    token.Plus | token.Minus -> precedence_term
    token.Star | token.Slash -> precedence_factor
    token.LeftParen | token.LeftBracket | token.Dot -> precedence_call
    _ -> precedence_lowest
  }
}

const precedence_lowest = 0

const precedence_pipe = 1

const precedence_equality = 2

const precedence_comparison = 3

const precedence_concat = 4

const precedence_term = 5

const precedence_factor = 6

const precedence_prefix = 7

const precedence_call = 8
