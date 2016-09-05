//
//  Prelude.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

func id<A>(_ a: A) -> A {
  return a
}

func const<A, B>(_ a: A) -> (B) -> A {
  return { _ in a }
}

func cons<C: RangeReplaceableCollection>(_ x: C.Iterator.Element) -> (C) -> C {
  return { xs in
    var xs = xs
    xs.insert(x, at: xs.startIndex)
    return xs
  }
}

func uncons<C: Collection>(_ xs: C) -> (C.Iterator.Element, C.SubSequence)? {
  if let head = xs.first {
    return (head, xs.suffix(from: xs.index(after: xs.startIndex)))
  } else {
    return nil
  }
}

func splitAt<C: Collection>(_ count: C.IndexDistance) -> (C) -> (C.SubSequence, C.SubSequence) {
  return { xs in
    let splitIndex = xs.index(xs.startIndex, offsetBy: count)
    if count <= xs.count {
      return (xs.prefix(upTo: splitIndex), xs.suffix(from: splitIndex))
    } else {
      return (xs.prefix(upTo: splitIndex), xs.suffix(0))
    }
  }
}

/// Fixed-point combinator for recursive closures.
func unimplemented<T>() -> T
{
  fatalError()
}

func rec<T, U>(f: (@escaping (((T) -> U), T) -> U)) -> ((T) -> U)
{
  var g: ((T) -> U) = { _ in unimplemented() }

  g = { f(g, $0) }

  return g
}

precedencegroup ChainingPrecedence {
  associativity: left
  higherThan: LogicalConjunctionPrecedence
  lowerThan: NilCoalescingPrecedence
}

precedencegroup ChoicePrecedence {
  associativity: left
  higherThan: LogicalConjunctionPrecedence
}

infix operator <*> : ChainingPrecedence
infix operator <*  : ChainingPrecedence
infix operator *> : ChainingPrecedence
infix operator <^> : ChainingPrecedence
infix operator <&> : ChainingPrecedence
infix operator >>- : ChainingPrecedence

infix operator <|> : ChoicePrecedence
