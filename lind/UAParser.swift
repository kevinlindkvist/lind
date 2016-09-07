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
  return char("0") *> pure(.zero)
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
  return (string((), "succ") *> UATermP) >>- { (_: inout(),t: UATerm) in pure(.succ(t)) }
}

let UAPred = _UAPred()
func _UAPred() -> UATermParser {
  return (string((), "pred") *> UATermP) >>- { (_: inout(), t: UATerm) in pure(.pred(t)) }
}

let UAIsZero = _UAIsZero()
func _UAIsZero() -> UATermParser {
  return (string((), "isZero") *> UATermP) >>- { (_: inout(), t: UATerm) in pure(.isZero(t)) }
}

// Parses an if-then-else statement.
let UAIfElse = _UAIfElse()
func _UAIfElse() -> UATermParser {
  let ifString = string((), "if")
  let thenString = string((), "then")
  let elseString = string((), "else")
  return (ifString *> UATermP) >>- { (_: inout(), conditional: UATerm) in
    return (thenString *> UATermP) >>- { (_: inout(), trueBranch: UATerm) in
      return (elseString *> UATermP) >>- { (_: inout(), falseBranch: UATerm) in
        let ifElse = IfElseUATerm(conditional: conditional,
                                trueBranch: trueBranch,
                                falseBranch: falseBranch)
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

func parseUntypedArithmetic(_ str: String) -> Result<((), UATerm), ParseError> {
  return parseOnly(untypedArithmetic(), input: (str.unicodeScalars, ()))
}

