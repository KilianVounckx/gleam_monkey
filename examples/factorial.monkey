let rec fact = fun(n)
    if n <= 0 then
        1
    else
        n * fact(n - 1)
in

print(integer_to_string(fact(5)))
