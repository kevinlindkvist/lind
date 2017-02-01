//
//  UntypedArithmeticParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Parser
import Result

typealias TermParser = Parser<String.UnicodeScalarView, (), Term>

/// Parses 0.
let Zero = _Zero()
private func _Zero() -> TermParser {
  return char("0") *> pure(.Zero)
}

/// Parses true.
let True = _True()
func _True() -> TermParser {
  return string("true") *> pure(.True)
}

/// Parses false.
let False = _False()
func _False() -> TermParser {
  return string("false") *> pure(.False)
}

let Succ = _Succ()
func _Succ() -> TermParser {
  return (string("succ") *> TermP) >>- { (ctxt, t: Term) in (pure(.Succ(t)), ctxt) }
}

let Pred = _Pred()
func _Pred() -> TermParser {
  return (string("pred") *> TermP) >>- { (ctxt, t: Term) in (pure(.Pred(t)), ctxt) }
}

let IsZero = _IsZero()
func _IsZero() -> TermParser {
  return (string("isZero") *> TermP) >>- { (ctxt, t: Term) in (pure(.IsZero(t)), ctxt) }
}

// Parses an if-then-else statement.
let IfElse = _IfElse()
func _IfElse() -> TermParser {
  return (string("if") *> TermP) >>- { (ctxt, conditional: Term) in
    return (( string("then") *> TermP) >>- { (ctxt, trueBranch: Term) in
      return (( string("else") *> TermP) >>- { (ctxt, falseBranch: Term) in
        let ifElse = IfElseTerm(conditional: conditional,
                                trueBranch: trueBranch,
                                falseBranch: falseBranch)
        return (pure(.If(ifElse)), ())
      }, ctxt)
    }, ctxt)
  }
}

/// Parses a term.
let TermP = _term()
private func _term() -> TermParser {
  return skipSpaces(())
    *> (IfElse <|> True <|> False <|> Zero <|> Succ <|> Pred <|> IsZero)
    <* skipSpaces(())
}

/// Parses an untyped arithmetic program.
func untypedArithmetic() -> TermParser {
  return TermP <* endOfInput()
}

public func parseUntypedArithmetic(_ str: String) -> Result<((), Term), ParseError> {
  return parseOnly(untypedArithmetic(), input: (str.unicodeScalars, ()))
}

