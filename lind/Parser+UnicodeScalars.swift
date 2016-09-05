//
//  Parser+UnicodeScalars.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

/// Matches characters satisfying `predicate`.
func satisfy<Ctxt>(context: Ctxt, _ predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return Parser { input in
    if let (head, tail) = uncons(input.0) where predicate(head) {
      return .Done(tail, input.1, head)
    } else {
      return .Failure(input, [], "satisfy")
    }
  }
}

/// Skips characters satisfying `predicate`.
func skip<Ctxt>(predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, ()> {
  return Parser { input in
    if let (head, tail) = uncons(input.0) where predicate(head) {
      return .Done(tail, input.1, ())
    } else {
      return .Failure(input, [], "skip")
    }
  }
}

/// Skips characters until `predicate` is not satisfied.
func skipWhile<Ctxt>(predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, ()> {
  return Parser { input in
    let ctxt = input.1
    return rec { skip in { input in
      if let (head, tail) = uncons(input) where predicate(head) {
        return skip(tail)
      } else {
        return .Done(input, ctxt, ())
      }
    }} (input.0)
  }
}

/// Parses up to `count` UnicodeScalars.
/// - Precondition: `count >= 0`
func take<Ctxt>(count: Int) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  precondition(count > 0, "`take(count)` called with `count` < 0")
  return Parser { input in
    if input.0.count >= count {
      let (prefix, suffix) = splitAt(count)(input.0)
      return .Done(suffix, input.1, prefix)
    } else {
      return .Failure(input, [], "`take(\(count))")
    }
  }
}

/// Parses zero or more UnicodeScalars satifsying `predicate`.
func takeWhile<Ctxt>(predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  return Parser { input in
    let ctxt = input.1
    return rec { take in { input, acc in
      if let (head, tail) = uncons(input) where predicate(head) {
        return take(tail, acc + [head])
      } else {
        return .Done(input, ctxt, acc)
      }
    }}(input.0, String.UnicodeScalarView())
  }
}

let spaces: String.UnicodeScalarView = [ " ", "\t", "\n", "\r" ]
func isSpace(c: UnicodeScalar) -> Bool {
  return spaces.contains(c)
}

func skipSpaces<Ctxt>(context: Ctxt) -> Parser<String.UnicodeScalarView, Ctxt, ()> {
  return skipMany(satisfy(context, isSpace))
}

/// Parses any one unicode scalar.
func any<Ctxt>(context: Ctxt) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy(context, const(true))
}

/// Parses a character matching `c`.
func char<Ctxt>(context: Ctxt, _ c: UnicodeScalar) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy(context) { $0 == c }
}

/// Parses a character not matching `c`.
func not<Ctxt>(context: Ctxt, _ c: UnicodeScalar) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy(context) { $0 != c }
}

/// Parses a string `str`.
func string<Ctxt>(context: Ctxt, _ str: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  return string(str, f: id)
}

/// Parses a string `str` after mapping `f` over `str` and the input to the
/// parser.
func string<Ctxt>(str: String.UnicodeScalarView, f: UnicodeScalar -> UnicodeScalar) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  return Parser { input in
    let strLength = str.count
    let prefix = input.0.prefix(strLength)
    if prefix.map(f) == str.map(f) {
      let suffix = input.0.suffixFrom(input.0.startIndex.advancedBy(strLength))
      return .Done(suffix, input.1, prefix)
    } else {
      return .Failure(input, [], "\(prefix) did not match \(str)")
    }
  }
}

/// Parses one UnicodeScalar that exists in `xs`.
func oneOf<Ctxt>(context: Ctxt, xs: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy(context) { xs.contains($0) }
}

/// Parses one UnicodeScalar that does not exist in `xs`.
func noneOf<Ctxt>(context: Ctxt, xs: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy(context) { !xs.contains($0) }
}