//
//  UntypedArithmeticParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Parswift

typealias TermParser = Parser<Term, String.CharacterView, ()>

/// Parses 0.
private func Zero() -> TermParser {
  return (keyword(identifier: "0") *> create(x: .Zero))()
}

/// Parses true.
func True() -> TermParser {
  return (keyword(identifier: "true") *> create(x: .True))()
}

/// Parses false.
func False() -> TermParser {
  return (keyword(identifier: "false") *> create(x:.False))()
}

func Succ() -> TermParser {
  return ((keyword(identifier: "succ") *> TermP) >>- { t in create(x: .Succ(t)) })()
}

func Pred() -> TermParser {
  return ((keyword(identifier: "pred") *> TermP) >>- { t in create(x: .Pred(t)) })()
}

func IsZero() -> TermParser {
  return ((keyword(identifier: "isZero") *> TermP) >>- { t in create(x: .IsZero(t)) })()
}

func keyword(identifier: String) -> ParserClosure<String, String.CharacterView, ()> {
  return attempt(parser: skipSpaces *> string(string: identifier) <* skipSpaces)
}

// Parses an if-then-else statement.
func IfElse() -> TermParser {
  return ((keyword(identifier: "if") *> TermP) >>- { conditional in
    return (keyword(identifier: "then") *> TermP) >>- { trueBranch in
      return (keyword(identifier: "else") *> TermP) >>- { falseBranch in
        let ifElse = IfElseTerm(conditional: conditional,
                                trueBranch: trueBranch,
                                falseBranch: falseBranch)
        return create(x: .If(ifElse))
      }
    }
  })()
}

/// Parses a term.
private func TermP() -> TermParser {
  return 
    (IfElse <|> True <|> False <|> Zero <|> Succ <|> Pred <|> IsZero)()
}

/// Parses an untyped arithmetic program.
func untypedArithmetic() -> TermParser {
  return TermP()
}

public func parseUntypedArithmetic(_ str: String) -> Either<ParseError, Term> {
  return parse(input: str.characters, with: untypedArithmetic)
}

