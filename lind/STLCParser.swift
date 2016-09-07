//
//  TermParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation

private typealias NamingContext = [String:Int]
private typealias TermParser = Parser<String.UnicodeScalarView, NamingContext, STLCTerm>

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
  return (string("succ") *> term) >>- { ctxt, t in (pure(.succ(t)), ctxt) }
}

private let pred = _pred()
private func _pred() -> TermParser {
  return (string("pred") *> term) >>- { ctxt, t in (pure(.pred(t)), ctxt) }
}

private let isZero = _isZero()
private func _isZero() -> TermParser {
  return (string( "isZero") *> term) >>- { ctxt, t in (pure(.isZero(t)), ctxt) }
}

private let identifier = _identifier()
private func _identifier() -> Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView> {
  let alphas = CharacterSet.alphanumerics
  return many1( satisfy { alphas.contains(UnicodeScalar($0.value)!) } )
}

private let variable = _variable()
private func _variable() -> TermParser {
  return identifier >>- { (context: NamingContext, t: String.UnicodeScalarView) in
    let id = String(t)
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
  return (string("if ") *> nonAppTerm) >>- { ctxt, conditional in
    return ((string(" then ") *> nonAppTerm) >>- { ctxt, tBranch in
      return ((string(" else ") *> nonAppTerm) >>- { ctxt, fBranch in
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
    return ((char(".") *> term) >>- { ctxt, t in
      var ctxt = ctxt
      ctxt.forEach { name, index in
        if (index != 0) {
          ctxt[name] = index - 1
        }
      }
      ctxt.removeValue(forKey: boundName)
      return (pure(.abs(boundName, t)), ctxt)
    }, ctxt)
  }
}

private let nonAppTerm = _nonAppTerm()
private func _nonAppTerm() -> TermParser {
  return (char("(") *> term <* char(")"))
    <|> lambda
    <|> ifElse
    <|> succ
    <|> pred
    <|> isZero
    <|> tmTrue
    <|> tmFalse
    <|> variable
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(p: nonAppTerm,
                 op: char(" ") *> pure( { t1, t2 in .app(t1, t2) }))
}

private func simplyTypedLambdaCalculus() -> TermParser {
  return term <* endOfInput()
}

func parseSimplyTypedLambdaCalculus(_ str: String) -> Result<([String:Int], STLCTerm), ParseError> {
  switch parseOnly(simplyTypedLambdaCalculus(), input: (str.unicodeScalars, [:])) {
  case let .success((g, term)): return .success(g, term)
  case let .failure(error): return .failure(error)
  }
}
