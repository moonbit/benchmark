enum Bdd {
  One
  Zero
  Node(Bdd, Int, Int, Bdd)
}

fn eval(bdd : Bdd, vars : Array[Bool]) -> Bool {
  match bdd {
    Zero => false
    One => true
    Node(l, i, _, r) => if vars[i] { eval(r, vars) } else { eval(l, vars) }
  }
}

fn getId(bdd : Bdd) -> Int {
  match bdd {
    Zero => 0
    One => 1
    Node(_, i, _, _) => i
  }
}

let initSize_1 : Int = 8 * 1024 - 1

struct Context {
  mut nodeC : Int
  mut sz_1 : Int
  mut htab : Array[List[Bdd]]
  mut n_times : Int
}

let ctx : Context = {
  nodeC: 0,
  sz_1: initSize_1,
  htab: Array::make(initSize_1, List::default()),
  n_times: 0,
}

fn hashVal(x : Int, y : Int, v : Int) -> Int {
  x.lsl(1) + y + v.lsl(2)
}

fn resize(newSize : Int) -> Unit {
  let arr : Array[List[Bdd]] = ctx.htab
  let newSz_1 : Int = newSize - 1
  let newArr : Array[List[Bdd]] = Array::make(newSize, List::default())
  fn copyBucket(bucket : List[Bdd]) -> Unit {
    match bucket {
      Nil => ()
      Cons(n, ns) =>
        match n {
          Node(l, v, _, h) => {
            let ind : Int = hashVal(getId(l), getId(h), v).land(newSz_1)
            newArr[ind] = Cons(n, newArr[ind])
            copyBucket(ns)
          }
          _ => panic()
        }
    }
  }

  for i = 0; i < ctx.sz_1; i = i + 1 {
    copyBucket(arr[i])
  }
  ctx.htab = newArr
  ctx.sz_1 = newSz_1
}

fn insert(
  idl : Int,
  idh : Int,
  v : Int,
  ind : Int,
  bucket : List[Bdd],
  newNode : Bdd
) -> Unit {
  if ctx.n_times <= ctx.sz_1 {
    ctx.htab[ind] = Cons(newNode, bucket)
    ctx.n_times = ctx.n_times + 1
  } else {
    resize(ctx.sz_1 + ctx.sz_1 + 2)
    let ind : Int = hashVal(idl, idh, v).land(ctx.sz_1)
    ctx.htab[ind] = Cons(newNode, ctx.htab[ind])
  }
}

fn mkNode(low : Bdd, v : Int, high : Bdd) -> Bdd {
  let idl : Int = getId(low)
  let idh : Int = getId(high)
  if idl == idh {
    low
  } else {
    let ind : Int = hashVal(idl, idh, v).land(ctx.sz_1)
    let bucket : List[Bdd] = ctx.htab[ind]
    fn lookup(b : List[Bdd]) -> Bdd {
      match b {
        Nil => {
          let n : Bdd = Node(low, v, ctx.nodeC, high)
          // TODO: Check if this is correct
          ctx.nodeC = ctx.nodeC + 1
          insert(getId(low), getId(high), v, ind, bucket, n)
          n
        }
        Cons(n, ns) =>
          match n {
            Node(l, v_, _, h) =>
              if v == v_ && idl == getId(l) && idh == getId(h) {
                n
              } else {
                lookup(ns)
              }
            _ => panic()
          }
      }
    }

    lookup(bucket)
  }
}

enum Ordering {
  Less
  Equal
  Greater
}

fn cmpVar(x : Int, y : Int) -> Ordering {
  if x < y {
    Ordering::Less
  } else if x > y {
    Ordering::Greater
  } else {
    Ordering::Equal
  }
}

let zero : Bdd = Zero

let one : Bdd = One

fn mkVar(x : Int) -> Bdd {
  mkNode(zero, x, one)
}

let cacheSize : Int = 1999

let andslot1 : Array[Int] = Array::make(cacheSize, 0)

let andslot2 : Array[Int] = Array::make(cacheSize, 0)

let andslot3 : Array[Bdd] = Array::make(cacheSize, zero)

let xorslot1 : Array[Int] = Array::make(cacheSize, 0)

let xorslot2 : Array[Int] = Array::make(cacheSize, 0)

let xorslot3 : Array[Bdd] = Array::make(cacheSize, zero)

let notslot1 : Array[Int] = Array::make(cacheSize, 0)

let notslot2 : Array[Bdd] = Array::make(cacheSize, one)

fn hash(x : Int, y : Int) -> Int {
  (x.lsl(1) + y) % cacheSize
}

fn not(n : Bdd) -> Bdd {
  match n {
    Zero => one
    One => zero
    Node(l, v, id, r) => {
      let h : Int = id % cacheSize
      if id == notslot1[h] {
        notslot2[h]
      } else {
        let f : Bdd = mkNode(not(l), v, not(r))
        notslot1[h] = id
        notslot2[h] = f
        f
      }
    }
  }
}

fn and2(n1 : Bdd, n2 : Bdd) -> Bdd {
  match n1 {
    Node(l1, v1, i1, r1) =>
      match n2 {
        Node(l2, v2, i2, r2) => {
          let h : Int = hash(i1, i2)
          if i1 == andslot1[h] && i2 == andslot2[h] {
            andslot3[h]
          } else {
            let f : Bdd = match cmpVar(v1, v2) {
              Ordering::Equal => mkNode(and2(l1, l2), v1, and2(r1, r2))
              Ordering::Less => mkNode(and2(l1, n2), v1, and2(r1, n2))
              Ordering::Greater => mkNode(and2(n1, l2), v2, and2(n1, r2))
            }
            andslot1[h] = i1
            andslot2[h] = i2
            andslot3[h] = f
            f
          }
        }
        Zero => zero
        One => n1
      }
    Zero => zero
    One => n2
  }
}

fn xor(n1 : Bdd, n2 : Bdd) -> Bdd {
  match n1 {
    Node(l1, v1, i1, r1) =>
      match n2 {
        Node(l2, v2, i2, r2) => {
          let h : Int = hash(i1, i2)
          if i1 == xorslot1[h] && i2 == xorslot2[h] {
            xorslot3[h]
          } else {
            let f : Bdd = match cmpVar(v1, v2) {
              Ordering::Equal => mkNode(xor(l1, l2), v1, xor(r1, r2))
              Ordering::Less => mkNode(xor(l1, n2), v1, xor(r1, n2))
              Ordering::Greater => mkNode(xor(n1, l2), v2, xor(n1, r2))
            }
            xorslot1[h] = i1
            xorslot2[h] = i2
            xorslot3[h] = f
            f
          }
        }
        Zero => n1
        One => not(n1)
      }
    Zero => n2
    One => not(n2)
  }
}

fn hwb(n : Int) -> Bdd {
  fn h(i : Int, j : Int) -> Bdd {
    if i == j {
      mkVar(i)
    } else {
      xor(and2(not(mkVar(j)), h(i, j - 1)), and2(mkVar(j), g(i, j - 1)))
    }
  }

  fn g(i : Int, j : Int) -> Bdd {
    if i == j {
      mkVar(i)
    } else {
      xor(and2(not(mkVar(i)), h(i + 1, j)), and2(mkVar(i), g(i + 1, j)))
    }
  }

  h(0, n - 1)
}

test "bdd" {
  let mut seed : Int = 0
  fn random() -> Bool {
    seed = seed * 25173 + 17431
    seed.land(1) > 0
  }

  fn randomVars(n : Int) -> Array[Bool] {
    let vars : Array[Bool] = Array::make(n, false)
    for i = 0; i < n; i = i + 1 {
      vars[i] = random()
    }
    vars
  }

  fn testHwb(bdd : Bdd, vars : Array[Bool]) -> Bool {
    let mut ntrue : Int = 0
    for i = 0; i < vars.length(); i = i + 1 {
      if vars[i] {
        ntrue = ntrue + 1
      }
    }
    if ntrue > 0 {
      eval(bdd, vars) == vars[ntrue - 1]
    } else {
      eval(bdd, vars) == false
    }
  }

  let n : Int = 22
  let ntests : Int = 100
  let bdd : Bdd = hwb(n)
  let mut succeeded : Bool = true
  for i = 1; i <= ntests; i = i + 1 {
    succeeded = succeeded && testHwb(bdd, randomVars(n))
  }
  if succeeded {
    panic()
  }
}
