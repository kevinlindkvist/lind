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
  let alphas = NSCharacterSet.alphanumericCharacterSet()
  return many1( satisfy([:]) { alphas.longCharacterIsMember($0.value) } )
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
  return char([:], "\\") *> identifier
    >>- { va in
      let boundName = String(va.1)
      var shiftedContext: NamingContext = [:]
      va.0.forEach { name, index in
        return shiftedContext[name] = index + 1
      }
      shiftedContext[boundName] = 0
      return char([:], ".") *> term
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
         f: (NamingContext, ULCTerm) -> TermParser) -> TermParser {
  return Parser { input in
    switch parse(parser, input: input) {
    case let .Failure(input2, labels, message):
      return .Failure(input2, labels, message)
    case let .Done(input2, context, output):
      return parse(f(context, output), input: (input2, context))
    }
  }
}

//private func chainl1(p: TermParser, _ op: Parser<String.UnicodeScalarView, NamingContext, (ULCTerm, ULCTerm) -> ULCTerm>) -> TermParser {
//  p >>- { x in
//    rec { recur in { x in
//      (op >>- { f in p >>- { y in recur(f.1(x.1, y.1)) } }) <|> pure(x.1)
//    }}
//  }
//}

private func chainl1(p: TermParser, _ op: Parser<String.UnicodeScalarView, NamingContext, (ULCTerm, ULCTerm) -> ULCTerm>) -> TermParser {
  func recur(_: x) {
    
  }
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(nonAppTerm, char([:], " ")
    *> pure( { t1, t2 in (t2.0, .app(t1.1, t2.1))})
  )
}

private func untypedLambdaCalculus() -> TermParser {
  return term <* endOfInput()
}

func parseUntypedLambdaCalculus(str: String) -> Result<([String:Int], ULCTerm), ParseError> {
  switch parseOnly(untypedLambdaCalculus(), input: (str.unicodeScalars, [:])) {
    case let .Success((g, term)): return .Success(g, term)
    case let .Failure(error): return .Failure(error)
  }
}
