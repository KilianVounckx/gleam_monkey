  $ cd $TESTDIR && gleam run --no-print-progress -- -e "nil"
  nil
  $ cd $TESTDIR && gleam run --no-print-progress -- -e "true"
  true
  $ cd $TESTDIR && gleam run --no-print-progress -- -e "false"
  false
  $ cd $TESTDIR && gleam run --no-print-progress -- -e "42"
  42
  $ cd $TESTDIR && gleam run --no-print-progress -- -e "42 + 69"
  111
  $ cd $TESTDIR && gleam run --no-print-progress -- -e "let x = 42 in let y = 69 in x + y"
  111
  $ cd $TESTDIR && gleam run --no-print-progress -- -e "let add = fun(x, y) x + y in add(42, 69)"
  111
  $ cd $TESTDIR && gleam run --no-print-progress -- -e "let rec fact = fun(n) if n <= 0 then 1 else n * fact(n - 1) in fact(5)"
  120
