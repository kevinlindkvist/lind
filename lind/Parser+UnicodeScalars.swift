//
//  Parser+UnicodeScalars.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

/// Matches characters satisfying `predicate`.
func satisfy<Ctxt>(_ predicate: @escaping (UnicodeScalar) -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return Parser { input in
    if let (head, tail) = uncons(input.0) , predicate(head) {
      return .done(tail, input.1, head)
    } else {
      return .failure(input, [], "satisfy")
    }
  }
}

/// Skips characters satisfying `predicate`.
func skip<Ctxt>(_ predicate: @escaping (UnicodeScalar) -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, ()> {
  return Parser { input in
    if let (head, tail) = uncons(input.0) , predicate(head) {
      return .done(tail, input.1, ())
    } else {
      return .failure(input, [], "skip")
    }
  }
}

/// Skips characters until `predicate` is not satisfied.
func skipWhile<Ctxt>(_ predicate: @escaping (UnicodeScalar) -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, ()> {
  return Parser { input in
    let ctxt = input.1
    return rec { skip, input in
      if let (head, tail) = uncons(input) , predicate(head) {
        return skip(tail)
      } else {
        return .done(input, ctxt, ())
      }
    } (input.0)
  }
}

/// Parses up to `count` UnicodeScalars.
/// - Precondition: `count >= 0`
func take<Ctxt>(_ count: Int) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  precondition(count > 0, "`take(count)` called with `count` < 0")
  return Parser { input in
    if input.0.count >= count {
      let (prefix, suffix) = splitAt(count)(input.0)
      return .done(suffix, input.1, prefix)
    } else {
      return .failure(input, [], "`take(\(count))")
    }
  }
}

/// Parses zero or more UnicodeScalars satifsying `predicate`.
func takeWhile<Ctxt>(_ predicate: @escaping (UnicodeScalar) -> Bool) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  return Parser { input in
    let ctxt = input.1
    return rec { take, input in
      if let (head, tail) = uncons(input.0) , predicate(head) {
        return take((tail, input.1 + [head]))
      } else {
        return .done(input.0, ctxt, input.1)
      }
    }((input.0, String.UnicodeScalarView()))
  }
}

let spaces: String.UnicodeScalarView = [ " ", "\t", "\n", "\r" ]
func isSpace(_ c: UnicodeScalar) -> Bool {
  return spaces.contains(c)
}

func skipSpaces<Ctxt>(_ context: Ctxt) -> Parser<String.UnicodeScalarView, Ctxt, ()> {
  return skipMany(satisfy(isSpace))
}

/// Parses any one unicode scalar.
func any<Ctxt>(_ context: Ctxt) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy(const(true))
}

/// Parses a character matching `c`.
func char<Ctxt>(_ c: UnicodeScalar) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy { $0 == c }
}

/// Parses a character not matching `c`.
func not<Ctxt>(_ context: Ctxt, _ c: UnicodeScalar) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy { $0 != c }
}

/// Parses a string `str`.
func string<Ctxt>(_ str: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  return string(str, f: id)
}

/// Parses a string `str` after mapping `f` over `str` and the input to the
/// parser.
func string<Ctxt>(_ str: String.UnicodeScalarView, f: @escaping (UnicodeScalar) -> UnicodeScalar) -> Parser<String.UnicodeScalarView, Ctxt, String.UnicodeScalarView> {
  return Parser { input in
    let strLength = str.count
    let prefix = input.0.prefix(strLength)
    if prefix.map(f) == str.map(f) {
      let suffix = input.0.suffix(from: input.0.index(input.0.startIndex, offsetBy: strLength))
      return .done(suffix, input.1, prefix)
    } else {
      return .failure(input, [], "\(prefix) did not match \(str)")
    }
  }
}

/// Parses one UnicodeScalar that exists in `xs`.
func oneOf<Ctxt>(_ context: Ctxt, xs: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy { xs.contains($0) }
}

/// Parses one UnicodeScalar that does not exist in `xs`.
func noneOf<Ctxt>(_ context: Ctxt, xs: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, Ctxt, UnicodeScalar> {
  return satisfy { !xs.contains($0) }
}
