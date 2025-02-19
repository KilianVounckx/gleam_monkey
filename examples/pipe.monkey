let add = fun(x, y) x + y in
let rec fact = fun(n) if n <= 0 then 1 else n * fact(n - 1) in
2 |> add(3) |> fact() |> integer_to_string() |> print()
