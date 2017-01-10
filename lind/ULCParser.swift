//
//  UntypedLambdaCalculusParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation

private typealias TermParser = Parser<String.UnicodeScalarView, NamingContext, ULCTerm>

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

private let lambda = _lambda()
private func _lambda() -> TermParser {
  return (char("\\") *> identifier)
    >>- { (context: NamingContext, identifier: String.UnicodeScalarView) in
      let boundName = String(identifier)
      var context = context
      context.forEach { name, index in
        return context[name] = index + 1
      }
      context[boundName] = 0
      return ((char(".") *> term)
        >>- { (context: NamingContext, t: ULCTerm) in
          var context = context
          context.forEach { name, index in
            if (index != 0) {
              context[name] = index - 1
            }
          }
          context.removeValue(forKey: boundName)
          return (pure(.abs(boundName, t)), context)
        }, context)
    }
}

private let nonAppTerm = _nonAppTerm()
private func _nonAppTerm() -> TermParser {
  return (char("(") *> term <* char(")")) <|> lambda <|> variable
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(p: nonAppTerm,
                 op: char(" ") *> pure( { t1, t2 in .app(t1, t2)}))
}

private func untypedLambdaCalculus() -> TermParser {
  return term <* endOfInput()
}

func parseUntypedLambdaCalculus(_ str: String) -> Result<([String:Int], ULCTerm), ParseError> {
  switch parseOnly(untypedLambdaCalculus(), input: (str.unicodeScalars, [:])) {
    case let .Success((g, term)): return .Success(g, term)
    case let .failure(error): return .failure(error)
  }
}
