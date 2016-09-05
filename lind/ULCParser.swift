//
//  UntypedLambdaCalculusParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation

private typealias NamingContext = [String:Int]

private typealias TermParser = Parser<String.UnicodeScalarView, NamingContext, ULCTerm>

private let identifier = _identifier()
private func _identifier() -> Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView> {
  let alphas = CharacterSet.alphanumerics
  return many1( satisfy([:]) { alphas.contains(UnicodeScalar($0.value)!) } )
}

private let variable = _variable()
private func _variable() -> TermParser {
  return identifier >>- {
    let context = ($0.0)
    let id = String($0.1)
    if let index = context[id] {
      return pure(.va(id, index))
    } else {
      let index = context.count
      return (pure(.va(id, index)))
    }
  }
}

private let lambda = _lambda()
private func _lambda() -> TermParser {
  return (char([:], "\\") *> identifier)
    >>- { va in
      let boundName = String(va.1)
      var shiftedContext: NamingContext = [:]
      va.0.forEach { name, index in
        return shiftedContext[name] = index + 1
      }
      shiftedContext[boundName] = 0
      return (char([:], ".") *> term)
      >>- { body in
        var unshiftedContext: NamingContext = [:]
        body.0.forEach { name, index in
          if (index != 0) {
            unshiftedContext[name] = index - 1
          }
        }
        return pure(.abs(boundName, body.1))
      }
    }
}

private let nonAppTerm = _nonAppTerm()
private func _nonAppTerm() -> TermParser {
  return (char([:], "(") *> term <* char([:], ")")) <|> lambda <|> variable
}

private func >>-(parser: TermParser,
         f: @escaping (NamingContext, ULCTerm) -> TermParser) -> TermParser {
  return Parser { input in
    switch parse(parser, input: input) {
    case let .failure(input2, labels, message):
      return .failure(input2, labels, message)
    case let .done(input2, context, output):
      return parse(f(context, output), input: (input2, context))
    }
  }
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(p: nonAppTerm,
                 op: char([:], " ") *> pure( { t1, t2 in .app(t1, t2)}))
}

private func untypedLambdaCalculus() -> TermParser {
  return term <* endOfInput()
}

func parseUntypedLambdaCalculus(_ str: String) -> Result<([String:Int], ULCTerm), ParseError> {
  switch parseOnly(untypedLambdaCalculus(), input: (str.unicodeScalars, [:])) {
    case let .success((g, term)): return .success(g, term)
    case let .failure(error): return .failure(error)
  }
}
