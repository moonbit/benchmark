fn fib(n : Int) -> Int {
  if n < 2 {
    1
  } else {
    fib(n - 1) + fib(n - 2)
  }
}

test "fib" {
  // @lib.assert(fib(40) == 165580141)
  @assertion.assert_eq(fib(40), 165580141)?
}
