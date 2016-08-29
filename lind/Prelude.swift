//
//  Prelude.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

func id<A>(a: A) -> A {
  return a
}

func const<A, B>(a: A) -> B -> A {
  return { _ in a }
}

func cons<C: RangeReplaceableCollectionType>(x: C.Generator.Element) -> C -> C {
  return { xs in
    var xs = xs
    xs.insert(x, atIndex: xs.startIndex)
    return xs
  }
}

func uncons<C: CollectionType>(xs: C) -> (C.Generator.Element, C.SubSequence)? {
  if let head = xs.first {
    return (head, xs.suffixFrom(xs.startIndex.successor()))
  } else {
    return nil
  }
}

func splitAt<C: CollectionType>(count: C.Index.Distance) -> C -> (C.SubSequence, C.SubSequence) {
  precondition(count >= 0, "`splitAt(count)` must have `count >= 0`.")

  return { xs in
    let splitIndex = xs.startIndex.advancedBy(count)
    if count <= xs.count {
      return (xs.prefixUpTo(splitIndex), xs.suffixFrom(splitIndex))
    } else {
      return (xs.prefixUpTo(splitIndex), xs.suffix(0))
    }
  }
}

/// Fixed-point combinator for recursive closures.
func rec<T, U>(f: (T -> U) -> T -> U) -> T -> U {
  return { f(rec(f))($0) }
}

infix operator >>-  { associativity left precedence 100 }

infix operator <|>  { associativity right precedence 130 }

infix operator <*>  { associativity left precedence 140 }
infix operator <*   { associativity left precedence 140 }
infix operator *>   { associativity left precedence 140 }

infix operator <^>  { associativity left precedence 140 }
infix operator <&>  { associativity left precedence 140 }

infix operator <?>  { associativity left precedence 0 }