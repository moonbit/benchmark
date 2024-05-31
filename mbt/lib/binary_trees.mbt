enum Tree[X] {
  Empty
  Node(Tree[X], X, Tree[X])
}

fn make(i : Int, d : Int) -> Tree[Int] {
  if d == 0 {
    Tree::Node(Tree::Empty, i, Tree::Empty)
  } else {
    let i2 = 2 * i
    let d = d - 1
    Tree::Node(make(i2 - 1, d), i, make(i2, d))
  }
}

fn check(tree : Tree[Int]) -> Int {
  match tree {
    Tree::Empty => 0
    Tree::Node(l, i, r) => i + check(l) - check(r)
  }
}

let min_depth = 4

let max_depth : Int = max(min_depth + 2, 10)

fn max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

// fn stretch_depth() -> Int {
//   max_depth + 1
// }

// let long_lived_tree : Tree[Int] = make(0, max_depth)

fn loop_depths(d : Int) -> Unit {
  for i = 0; i < (max_depth - d) / 2 + 1 - 1; i = i + 1 {
    let d = d + i * 2
    let one = 1
    let niter = one.lsl(max_depth - d + min_depth)
    let mut c = 0
    for i = 1; i <= niter; i = i + 1 {
      c = c + check(make(i, d)) + check(make(-i, d))
    }
  }
}

test "binary_trees" {
  loop_depths(min_depth)
}
