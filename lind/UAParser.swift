//
//  UntypedArithmeticParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

typealias UATermParser = Parser<String.UnicodeScalarView, (), UATerm>

/// Parses 0.
let UAZero = _UAZero()
private func _UAZero() -> UATermParser {
  return char((), "0") *> pure(.zero)
}

/// Parses true.
let UATrue = _UATrue()
func _UATrue() -> UATermParser {
  return string((), "true") *> pure(.tmTrue)
}

/// Parses false.
let UAFalse = _UAFalse()
func _UAFalse() -> UATermParser {
  return string((), "false") *> pure(.tmFalse)
}

let UASucc = _UASucc()
func _UASucc() -> UATermParser {
  return string((), "succ") *> UATermP >>- { t in pure(.succ(t.1)) }
}

let UAPred = _UAPred()
func _UAPred() -> UATermParser {
  return string((), "pred") *> UATermP >>- { t in pure(.pred(t.1)) }
}

let UAIsZero = _UAIsZero()
func _UAIsZero() -> UATermParser {
  return string((), "isZero") *> UATermP >>- { t in pure(.isZero(t.1)) }
}

// Parses an if-then-else statement.
let UAIfElse = _UAIfElse()
func _UAIfElse() -> UATermParser {
  let ifString = string((), "if")
  let thenString = string((), "then")
  let elseString = string((), "else")
  return ifString *> UATermP >>- { conditional in
    return thenString *> UATermP >>- { trueBranch in
      return elseString *> UATermP >>- { falseBranch in
        let ifElse = IfElseUATerm(conditional: conditional.1,
                                trueBranch: trueBranch.1,
                                falseBranch: falseBranch.1)
        return pure(.ifElse(ifElse))
      }
    }
  }
}

/// Parses a term.
let UATermP = _term()
private func _term() -> UATermParser {
  return skipSpaces(())
    *> (UAIfElse <|> UATrue <|> UAFalse <|> UAZero <|> UASucc <|> UAPred <|> UAIsZero)
    <* skipSpaces(())
}

/// Parses an untyped arithmetic program.
func untypedArithmetic() -> UATermParser {
  return UATermP <* endOfInput()
}

func parseUntypedArithmetic(str: String) -> Result<((), UATerm), ParseError> {
  return parseOnly(untypedArithmetic(), input: (str.unicodeScalars, ()))
}

