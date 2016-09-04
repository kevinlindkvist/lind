//
//  UntypedLambdaCalculusParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation

typealias NamingContext = [String:Int]
typealias ParseResult = (NamingContext, LCTerm)

private typealias TermParser = Parser<String.UnicodeScalarView, ParseResult>

private func chainl1(p: NamingContext -> TermParser,
                     _ firstContext: NamingContext,
                     _ op: Parser<String.UnicodeScalarView, (ParseResult, ParseResult) -> ParseResult>) -> TermParser {
  return p(firstContext) >>- { x in
    rec { recur in { x in
      (op >>- { f in
        p(x.0) >>- { y in
          recur(f(x, y))
        }
        }) <|> pure(x)
      }}(x)
  }
}

private let identifier = _identifier()
private func _identifier() -> UVUVParser {
  let alphas = NSCharacterSet.alphanumericCharacterSet()
  return many1( satisfy { alphas.longCharacterIsMember($0.value) } )
}

private func variable(context: NamingContext) -> TermParser {
  return identifier <&> {
    let id = String($0)
    if let index = context[id] {
      return (context, .va(id, index))
    } else {
      let index = context.count
      return (union(context, [id:index]), .va(id, index))
    }
  }
}

private func lambda(context: NamingContext) -> TermParser {
  return char("\\") *> identifier
    >>- { va in
      let boundName = String(va)
      var shiftedContext: NamingContext = [:]
      context.forEach { name, index in
        return shiftedContext[name] = index + 1
      }
      shiftedContext[boundName] = 0
      return char(".") *> nonAppTerm(shiftedContext)
      >>- { body in
        var unshiftedContext: NamingContext = [:]
        body.0.forEach { name, index in
          if (index != 0) {
            unshiftedContext[name] = index - 1
          }
        }
        return pure((unshiftedContext, .abs(boundName, body.1)))
      }
    }
}

private func nonAppTerm(context: NamingContext) -> TermParser {
  return (char("(") *> term(context) <* char(")")) <|> lambda(context) <|> variable(context)
}

private func term(context: NamingContext) -> TermParser {
  return chainl1(nonAppTerm, context, char(" ")
    *> pure( { t1, t2 in (t2.0, .app(t1.1, t2.1))})
  )
}

private func untypedLambdaCalculus() -> TermParser {
  return term([:]) <* endOfInput()
}

func parseUntypedLambdaCalculus(str: String) -> Result<(NamingContext, LCTerm), ParseError> {
  switch parseOnly(untypedLambdaCalculus(), input: str.unicodeScalars) {
    case let .Success((g, term)): return .Success(g, term)
    case let .Failure(error): return .Failure(error)
  }
}
