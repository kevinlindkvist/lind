//
//  UntypedArithmeticParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

private typealias UATermParser = Parser<String.UnicodeScalarView, UATerm>

/// Parses 0.
private func zero() -> UATermParser {
  return char("0") *> pure(.zero)
}

/// Parses true.
private func tmTrue() -> UATermParser {
  return string("true") *> pure(.tmTrue)
}

/// Parses false.
private func tmFalse() -> UATermParser {
  return string("false") *> pure(.tmFalse)
}

private func succ() -> UATermParser {
  return string("succ") *> term() >>- { t in pure(.succ(t)) }
}

private func pred() -> UATermParser {
  return string("pred") *> term() >>- { t in pure(.pred(t)) }
}

private func isZero() -> UATermParser {
  return string("isZero") *> term() >>- { t in pure(.isZero(t)) }
}

// Parses an if-then-else statement.
private func ifElse() -> UATermParser {
  let ifString = string("if")
  let thenString = string("then")
  let elseString = string("else")
  return ifString *> term() >>- { conditional in
    return thenString *> term() >>- { trueBranch in
      return elseString *> term() >>- { falseBranch in
        let ifElse = IfElseUATerm(conditional: conditional,
                                trueBranch: trueBranch,
                                falseBranch: falseBranch)
        return pure(.ifElse(ifElse))
      }
    }
  }
}

/// Parses a term.
private func term() -> UATermParser {
  return skipSpaces() *> (ifElse() <|> tmTrue() <|> tmFalse() <|> zero() <|> succ() <|> pred() <|> isZero()) <* skipSpaces()
}

/// Parses an untyped arithmetic program.
func untypedArithmetic() -> Parser<String.UnicodeScalarView, UATerm> {
  return term() <* endOfInput()
}

func parseUntypedArithmetic(str: String) -> Result<UATerm, ParseError> {
  return parseOnly(untypedArithmetic(), input: str.unicodeScalars)
}

