//
//  TermParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation

// # Note on capitalization.
// 
// Keyword enum members are capitalized. Parsers for values and specific characters are capitalized. 
// Convenience parsers for keywords and built-ins use CamelCase. All other parsers use camelCase.

fileprivate typealias TermParser = Parser<String.UnicodeScalarView, NamingContext, STLCTerm>
fileprivate typealias TypeParser = Parser<String.UnicodeScalarView, NamingContext, STLCType>
fileprivate typealias StringParser = Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView>

fileprivate enum KeyWord: String.UnicodeScalarView {
  // Built ins
  case IF = "if"
  case THEN = "then"
  case ELSE = "else"
  case SUCC = "succ"
  case PRED = "pred"
  case ISZERO = "isZero"
  // Values
  case ZERO = "0"
  case UNIT = "unit"
  case FALSE = "false"
  case TRUE = "true"
  // Base Types
  case BOOL = "bool"
  case INT = "int"
  // Special characters
  case COLON = ":"
  case PERIOD = "."
  case BACKSLASH = "\\"
  // Extensions
  case AS = "as"
  case WILD = "_"
  case LET = "let"
  case IN = "in"
}

private func keyword(_ word: KeyWord) -> StringParser {
  return skipSpaces() *> string(word.rawValue)
}

private let Succ = succ()
private func succ() -> TermParser {
  return (keyword(.SUCC) *> skipSpaces() *> term) >>- { ctxt, t in (pure(.Succ(t)), ctxt) }
}

private let Pred = pred()
private func pred() -> TermParser {
  return (keyword(.PRED) *> skipSpaces() *> term) >>- { ctxt, t in (pure(.Pred(t)), ctxt) }
}

private let IsZero = isZero()
private func isZero() -> TermParser {
  return (keyword(.ISZERO) *> skipSpaces() *> term) >>- { ctxt, t in (pure(.IsZero(t)), ctxt) }
}

// MARK: - Types

private let baseType = _baseType()
private func _baseType() -> TypeParser {
  return Bool <|> Int <|> Unit <|> (identifier >>- { context, identifier in
    (pure(.base(String(identifier))), context)
  })
}

private let type = _type()
private func _type() -> TypeParser {
  return chainl1(p: baseType, op: string("->") *> pure({ t1, t2 in .t_t(t1, t2) }))
}

fileprivate let Bool = bool()
fileprivate func bool() -> TypeParser {
  return keyword(.BOOL) *> pure(.bool)
}

fileprivate let Int = int()
fileprivate func int() -> TypeParser {
  return keyword(.INT) *> pure(.int)
}

fileprivate let Unit = unit_ty()
fileprivate func unit_ty() -> TypeParser {
  return keyword(.UNIT) *> pure(.Unit)
}

// MARK: - Values

fileprivate let Value = value()
fileprivate func value() -> TermParser {
  return TRUE <|> FALSE <|> ZERO <|> UNIT <|> LAMBDA <|> variable
}

private let UNIT = _unit()
private func _unit() -> TermParser {
  return keyword(.UNIT) *> pure(.Unit)
}

private let TRUE = _true()
private func _true() -> TermParser {
  return keyword(.TRUE) *> pure(.True)
}

private let FALSE = _false()
private func _false() -> TermParser {
  return keyword(.FALSE) *> pure(.False)
}

fileprivate let ZERO = zero()
fileprivate func zero() -> TermParser {
  return keyword(.ZERO) *> pure(.Zero)
}

// MARK: - Variables

private let identifier = _identifier()
private func _identifier() -> Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView> {
  let alphas = CharacterSet.alphanumerics
  return skipSpaces() *> many1( satisfy { alphas.contains(UnicodeScalar($0.value)!) } )
}

private let variable = _variable()
private func _variable() -> TermParser {
  return identifier >>- { (context: NamingContext, t: String.UnicodeScalarView) in
    if (KeyWord(rawValue: t) != nil) {
      return (fail("Variable was keyword"), context)
    }

    let id = String(t)
    if let index = context[id] {
      return (pure(.va(id, index)), context)
    } else {
      let index = context.count
      return (pure(.va(id, index)), union(context, [id:index]))
    }
  }
}

// MARK: - If Statements

private let IfElse = ifElse()
private func ifElse() -> TermParser {
  return (If *> term) >>- { ctxt, conditional in
  return ((Then *> term) >>- { ctxt, tBranch in
  return ((Else *> term) >>- { ctxt, fBranch in
  return (pure(.If(conditional, tBranch, fBranch)), ctxt)
  }, ctxt)
  }, ctxt)
  }
}

fileprivate let If = _if()
fileprivate func _if() -> StringParser {
  return keyword(.IF) <* skipSpaces()
}

fileprivate let Then = then()
fileprivate func then() -> StringParser {
  return keyword(.THEN) <* skipSpaces()
}

fileprivate let Else = _else()
fileprivate func _else() -> StringParser {
  return keyword(.ELSE) <* skipSpaces()
}

// ΜARK: - λ

private let LAMBDA = _lambda()
private func _lambda() -> TermParser {
  return (BACKSLASH *> identifier) >>- { ctxt, identifier in

  let ctxt = shiftContext(ctxt: ctxt, identifier: identifier)

  return ((COLON *> type) >>- { ctxt, type in
  return ((PERIOD *> term) >>- { ctxt, t in
      
  let ctxt = unshiftContext(ctxt: ctxt, identifier: identifier)
    
  return (pure(.abs(String(identifier), type, t)), ctxt)
  }, ctxt)
  }, ctxt)
  }
}

fileprivate let PERIOD = period()
fileprivate func period() -> StringParser {
  return keyword(.PERIOD)
}

fileprivate let COLON = colon()
fileprivate func colon() -> StringParser {
  return keyword(.COLON)
}

fileprivate let BACKSLASH = backslash()
fileprivate func backslash() -> StringParser {
  return keyword(.BACKSLASH)
}

// MARK: Context Modifications

fileprivate func shiftContext(ctxt: NamingContext, identifier: String.UnicodeScalarView) -> NamingContext {
  var ctxt = ctxt
  ctxt.forEach { name, index in
    return ctxt[name] = index + 1
  }
  ctxt[String(identifier)] = 0
  return ctxt
}

fileprivate func unshiftContext(ctxt: NamingContext, identifier: String.UnicodeScalarView) -> NamingContext {
  var ctxt = ctxt
  ctxt.forEach { name, index in
    if (index != 0) {
      ctxt[name] = index - 1
    }
  }
  ctxt.removeValue(forKey: String(identifier))
  return ctxt
}

// MARK: - Built Ins

fileprivate let builtIn = _builtIn()
fileprivate func _builtIn() -> TermParser {
  return Succ <|> Pred <|> IsZero <|> IfElse <|> Let
}

// MARK: - Atoms

fileprivate let atom = _atom()
private func _atom() -> TermParser {
  return (char("(") *> sequence <* char(")")) <|> builtIn <|> Value
}

// MARK: - Ascription

fileprivate let ascription = _ascription()
fileprivate func _ascription() -> TypeParser {
  return As *> type
}

fileprivate let As = _as()
fileprivate func _as() -> StringParser {
  return keyword(.AS)
}

// MARK: - Assignment

fileprivate let Let = _let()
fileprivate func _let() -> TermParser {
  return (keyword(.LET) *> identifier) >>- { (ctxt: NamingContext, identifier: String.UnicodeScalarView) in
  return ((char("=") *> term) >>- { (ctxt: NamingContext, t1: STLCTerm) in
  return ((keyword(.IN) *> skipSpaces() *> term) >>- { (ctxt: NamingContext, t2: STLCTerm) in
    if let T1 = typeOf(t: t1, context: [:]) {
      return (pure(.app(.abs(String(identifier), T1, t2), t1)), ctxt)
    } else {
      return (fail("Could not determine type of \(t1)"), ctxt)
    }
  }, ctxt)
  }, ctxt)
  }
}

// MARK: - Program

private let sequence = _sequence()
private func _sequence() -> TermParser {
  return chainl1(p: term,
                 op: (skipSpaces() *> char(";") <* skipSpaces())
                  *> pure ({ t1, t2 in return .app(.abs("_", .Unit, t2), t1) }))
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(p: nonAppTerm,
                 op: char(" ") *> skipSpaces() *> pure( { t1, t2 in .app(t1, t2) }))
}

private let nonAppTerm = _nonAppTerm()
private func _nonAppTerm() -> TermParser {
  return atom >>- { ctxt, term in
    // After an atom is parsed, check if there is an ascription, otherwise purely return the atom.
    return ((ascription >>- { ctxt, type in
      return (pure(.app(.abs("_", type, .va("_", 0)), term)), ctxt)})
      <|> pure(term), ctxt)
  }
}

private func simplyTypedLambdaCalculus() -> TermParser {
  return sequence <* endOfInput()
}

func parseSimplyTypedLambdaCalculus(_ str: String) -> Result<([String:Int], STLCTerm), ParseError> {
  switch parseOnly(simplyTypedLambdaCalculus(), input: (str.unicodeScalars, [:])) {
  case let .success((g, term)): return .success(g, term)
  case let .failure(error): return .failure(error)
  }
}
