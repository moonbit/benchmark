fn taku(a : (Int, Int, Int)) -> Int {
  let (x, y, z) = a
  if x > y {
    taku((taku((x - 1, y, z)), taku((y - 1, z, x)), taku((z - 1, x, y))))
  } else {
    z
  }
}

fn repeat_u(n : Int, acc : Int) -> Int {
  if n <= 0 {
    acc
  } else {
    repeat_u(n - 1, acc + taku((18, 12, 6)))
  }
}

test "taku" {
  @assertion.assert_eq(repeat_u(2000, 0), 14000)?
}
