//
//  UntypedLambdaCalculusParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation

private typealias TermParser = Parser<String.UnicodeScalarView, LCTerm>

private let identifier = _identifier()
private func _identifier() -> UVUVParser {
  let alphas = NSCharacterSet.alphanumericCharacterSet()
  return many1( satisfy { alphas.longCharacterIsMember($0.value) } )
}

private let variable = _variable()
private func _variable() -> TermParser {
  return identifier <&> { .variable(name: String($0)) }
}

private let lambda = _lambda()
private func _lambda() -> TermParser {
  return char("\\") *> identifier
    >>- { variable in char(".") *> nonApplicationTerm
    >>- { body in
      return pure(.abstraction(name: String(variable), body: body))
    }
    }
}

private let nonApplicationTerm = _nonApplicationTerm()
private func _nonApplicationTerm() -> TermParser {
  return (char("(") *> term <* char(")")) <|> lambda <|> variable
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1 (nonApplicationTerm, char(" ")
    *> pure( { t1, t2 in .application(lhs: t1, rhs: t2) })
  )
}

func untypedLambdaCalculus() -> Parser<String.UnicodeScalarView, LCTerm> {
  return term <* endOfInput()
}

func parseUntypedLambdaCalculus(str: String) -> Result<LCTerm, ParseError> {
  return parseOnly(untypedLambdaCalculus(), input: str.unicodeScalars)
}
