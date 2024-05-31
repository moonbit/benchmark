fn takc(x : Int, y : Int, z : Int) -> Int {
  if x > y {
    takc(takc(x - 1, y, z), takc(y - 1, z, x), takc(z - 1, x, y))
  } else {
    z
  }
}

fn repeat(n : Int, acc : Int) -> Int {
  if n <= 0 {
    acc
  } else {
    repeat(n - 1, acc + takc(18, 12, 6))
  }
}

test "takc" {
  @assertion.assert_eq(repeat(2000, 0), 14000)?
}
