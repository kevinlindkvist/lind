//
//  TermParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation

fileprivate typealias NamingContext = [String:Int]
fileprivate typealias TermParser = Parser<String.UnicodeScalarView, NamingContext, STLCTerm>
fileprivate typealias TypeParser = Parser<String.UnicodeScalarView, NamingContext, STLCType>

fileprivate let keywords = [
  // Simply Typed Lambda Calculus
  "if", "else", "then", "succ", "pred", "isZero", "0",
  // Extensions
  "unit", "_", "as",
]

private func keyword(_ str: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView> {
  return skipSpaces() *> string(str);
}

private let baseType = _baseType()
private func _baseType() -> TypeParser {
  return (string("bool") *> pure(.bool))
    <|> (string("int") *> pure(.nat))
    <|> (string("unit") *> pure(.unit))
    <|> (identifier >>- { (context: NamingContext, identifier: String.UnicodeScalarView) in
      (pure(.base(String(identifier))), context) })
}

private let type = _type()
private func _type() -> TypeParser {
  return chainl1(p: baseType, op: string("->") *> pure({ t1, t2 in .t_t(t1, t2) }))
}

private let unit = _unit()
private func _unit() -> TermParser {
  return string("unit") *> pure(.unit)
}

private let zero = _zero()
private func _zero() -> TermParser {
  return char("0") *> pure(.zero)
}

private let tmTrue = _true()
private func _true() -> TermParser {
  return string("true") *> pure(.tmTrue)
}

private let tmFalse = _false()
private func _false() -> TermParser {
  return string("false") *> pure(.tmFalse)
}

private let succ = _succ()
private func _succ() -> TermParser {
  return (string("succ") *> skipSpaces() *> term) >>- { ctxt, t in (pure(.succ(t)), ctxt) }
}

private let pred = _pred()
private func _pred() -> TermParser {
  return (string("pred") *> skipSpaces() *> term) >>- { ctxt, t in (pure(.pred(t)), ctxt) }
}

private let isZero = _isZero()
private func _isZero() -> TermParser {
  return (string( "isZero") *> skipSpaces() *> term) >>- { ctxt, t in (pure(.isZero(t)), ctxt) }
}

private let identifier = _identifier()
private func _identifier() -> Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView> {
  let alphas = CharacterSet.alphanumerics
  print(alphas.contains(";"))
  return many1( satisfy { alphas.contains(UnicodeScalar($0.value)!) } )
}

private let variable = _variable()
private func _variable() -> TermParser {
  return identifier >>- { (context: NamingContext, t: String.UnicodeScalarView) in
    let id = String(t)
    if keywords.contains(id) {
      return (fail("variable was keyword"), context)
    }
    if let index = context[id] {
      return (pure(.va(id, index)), context)
    } else {
      let index = context.count
      return (pure(.va(id, index)), union(context, [id:index]))
    }
  }
}

private let ifElse = _ifElse()
private func _ifElse() -> TermParser {
  return (keyword("if") *> term) >>- { ctxt, conditional in
    return ((keyword("then") *> term) >>- { ctxt, tBranch in
      return ((keyword("else") *> term) >>- { ctxt, fBranch in
        return (pure(.ifElse(conditional, tBranch, fBranch)), ctxt)
      }, ctxt)
    }, ctxt)
  }
}

private let lambda = _lambda()
private func _lambda() -> TermParser {
  return (char("\\") *> identifier) >>- { ctxt, identifier in
    let boundName = String(identifier)
    var ctxt = ctxt
    ctxt.forEach { name, index in
      return ctxt[name] = index + 1
    }
    ctxt[boundName] = 0
    return ((char(":") *> type) >>- { ctxt, type in
      return ((char(".") *> sequence) >>- { ctxt, t in
        var ctxt = ctxt
        ctxt.forEach { name, index in
          if (index != 0) {
            ctxt[name] = index - 1
          }
        }
        ctxt.removeValue(forKey: boundName)
        return (pure(.abs(boundName, type, t)), ctxt)
      }, ctxt)
    }, ctxt)
  }
}

private let atom = _atom()
private func _atom() -> TermParser {
  return skipSpaces()
    *> ((char("(") *> sequence <* char(")"))
      <|> lambda
      <|> ifElse
      <|> succ
      <|> pred
      <|> isZero
      <|> tmTrue
      <|> tmFalse
      <|> zero
      <|> unit
      <|> variable)
}

private let ascription = _ascription()
private func _ascription() -> TypeParser {
  return skipSpaces() *> keyword("as") *> skipSpaces() *> type
}

private let nonAppTerm = _nonAppTerm()
private func _nonAppTerm() -> TermParser {
  return atom >>- { ctxt, term in
    let deriveAs: TermParser = ascription >>- { ctxt, type in
      return (pure(.app(.abs("_", type, .va("_", 0)), term)), ctxt)
    }
    return (deriveAs <|> pure(term), ctxt)
  }
}

private let sequence = _sequence()
private func _sequence() -> TermParser {
  return chainl1(p: term,
                 op: (skipSpaces() *> char(";") <* skipSpaces())
                  *> pure ({ t1, t2 in return .app(.abs("_", .unit, t2), t1) }))
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(p: nonAppTerm,
                 op: char(" ") *> skipSpaces() *> pure( { t1, t2 in .app(t1, t2) }))
}

private func simplyTypedLambdaCalculus() -> TermParser {
  return sequence <* endOfInput()
}

func parseSimplyTypedLambdaCalculus(_ str: String) -> Result<([String:Int], STLCTerm), ParseError> {
  switch parseOnly(simplyTypedLambdaCalculus(), input: (str.unicodeScalars, [:])) {
  case let .success((g, term)): return .success(g, term)
  case let .failure(error): return .failure(error)
  }
}
