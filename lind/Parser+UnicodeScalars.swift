//
//  Parser+UnicodeScalars.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

/// Matches characters satisfying `predicate`.
func satisfy(predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, UnicodeScalar> {
  return Parser { input in
    if let (head, tail) = uncons(input) where predicate(head) {
      return .Done(tail, head)
    } else {
      return .Failure(input, [], "satisfy")
    }
  }
}

/// Skips characters satisfying `predicate`.
func skip(predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, ()> {
  return Parser { input in
    if let (head, tail) = uncons(input) where predicate(head) {
      return .Done(tail, ())
    } else {
      return .Failure(input, [], "skip")
    }
  }
}

/// Skips characters until `predicate` is not satisfied.
func skipWhile(predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, ()> {
  return Parser { input in
    rec { skip in { input in
      if let (head, tail) = uncons(input) where predicate(head) {
        return skip(tail)
      } else {
        return .Done(input, ())
      }
    }} (input)
  }
}

/// Parses up to `count` UnicodeScalars.
/// - Precondition: `count >= 0`
func take(count: Int) -> Parser<String.UnicodeScalarView, String.UnicodeScalarView> {
  precondition(count > 0, "`take(count)` called with `count` < 0")
  return Parser { input in
    if input.count >= count {
      let (prefix, suffix) = splitAt(count)(input)
      return .Done(suffix, prefix)
    } else {
      return .Failure(input, [], "`take(\(count))")
    }
  }
}

/// Parses zero or more UnicodeScalars satifsying `predicate`.
func takeWhile(predicate: UnicodeScalar -> Bool) -> Parser<String.UnicodeScalarView, String.UnicodeScalarView> {
  return Parser { input in
    rec { take in { input, acc in
      if let (head, tail) = uncons(input) where predicate(head) {
        return take(tail, acc + [head])
      } else {
        return .Done(input, acc)
      }
    }}(input, String.UnicodeScalarView())
  }
}

let spaces: String.UnicodeScalarView = [ " ", "\t", "\n", "\r" ]
func isSpace(c: UnicodeScalar) -> Bool {
  return spaces.contains(c)
}

let skipSpaces = _skipSpaces()
func _skipSpaces() -> Parser<String.UnicodeScalarView, ()> {
  return skipMany(satisfy(isSpace))
}

/// `Parser<String.UnicodeScalarView, UnicodeScalar>`
typealias UVUSParser = Parser<String.UnicodeScalarView, UnicodeScalar>
/// `Parser<String.UnicodeScalarView, String.UnicodeScalarView>`
typealias UVUVParser = Parser<String.UnicodeScalarView, String.UnicodeScalarView>

/// Parses any one unicode scalar.
func any() -> UVUSParser {
  return satisfy(const(true))
}

/// Parses a character matching `c`.
func char(c: UnicodeScalar) -> UVUSParser {
  return satisfy { $0 == c }
}

/// Parses a character not matching `c`.
func not(c: UnicodeScalar) -> UVUSParser {
  return satisfy { $0 != c }
}

/// Parses a string `str`.
func string(str: String.UnicodeScalarView) -> UVUVParser {
  return string(str, f: id)
}

/// Parses a string `str` after mapping `f` over `str` and the input to the
/// parser.
func string(str: String.UnicodeScalarView, f: UnicodeScalar -> UnicodeScalar) -> UVUVParser {
  return Parser { input in
    let strLength = str.count
    let prefix = input.prefix(strLength)
    if prefix.map(f) == str.map(f) {
      let suffix = input.suffixFrom(input.startIndex.advancedBy(strLength))
      return .Done(suffix, prefix)
    } else {
      return .Failure(input, [], "\(prefix) did not match \(str)")
    }
  }
}

/// Parses one UnicodeScalar that exists in `xs`.
func oneOf(xs: String.UnicodeScalarView) -> UVUSParser {
  return satisfy { xs.contains($0) }
}

/// Parses one UnicodeScalar that does not exist in `xs`.
func noneOf(xs: String.UnicodeScalarView) -> UVUSParser {
  return satisfy { !xs.contains($0) }
}