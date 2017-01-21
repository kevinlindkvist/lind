//
//  LindParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import Result

// # Note on capitalization.
// 
// Keyword enum members are capitalized. Parsers for values and specific characters are capitalized.
// Convenience parsers for keywords and built-ins use CamelCase. All other parsers use camelCase.

fileprivate enum Keyword: String.UnicodeScalarView {
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

public typealias ParseResult = Result<(TermContext, Term), ParseError>

public func ==(lhs: ParseResult, rhs: ParseResult) -> Bool {
  return true
}

private typealias TermParser = Parser<String.UnicodeScalarView, TermContext, Term>
private typealias TypeParser = Parser<String.UnicodeScalarView, TermContext, Type>
private typealias StringParser = Parser<String.UnicodeScalarView, TermContext, String.UnicodeScalarView>

public func parse(input: String, terms: TermContext) -> ParseResult {
  return parseOnly(lind(), input: (input.unicodeScalars, terms))
}

private func lind() -> TermParser {
  return sequence <* endOfInput()
}

private let sequence = _sequence()
private func _sequence() -> TermParser {
  return chainl1(p: term,
                 op: (skipSpaces() *> char(";") <* skipSpaces())
                  *> pure ({ t1, t2 in
                    let abstraction: Term = .Abstraction(parameter: "_",
                                                         parameterType: .Unit,
                                                         body: t2)
                    return .Application(left: abstraction, right: t1)
                  }))
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(p: nonApplicationTerm,
                 op: char(" ") *> skipSpaces() *> pure( { t1, t2 in
                  .Application(left: t1, right: t2)
                 }))
}

private let nonApplicationTerm = _nonApplicationTerm()
private func _nonApplicationTerm() -> TermParser {
  return atom >>- { context, term in
    // After an atom is parsed, check if there is an ascription, otherwise purely return the atom.
    return ((ascription
      >>- { context, type in
        let body: Term = .Variable(name: "_", index: 0)
        let abstraction: Term = .Abstraction(parameter: "_", parameterType: type, body: body)
        return (pure(.Application(left: abstraction, right: term)), context)
      })
      <|> pure(term), context)
  }
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
  // Let is a slightly different derived form in that it actually runs 
  // the typechecker to verify the statement.
  return (keyword(.LET) *> identifier)
    >>- { (context: TermContext, identifier: String.UnicodeScalarView) in
      return ((char("=") *> term)
        >>- { (context: TermContext, t1: Term) in
          return ((keyword(.IN) *> skipSpaces() *> term)
            >>- { (context: TermContext, t2: Term) in
                let result = typeOf(term: t1, context: [:])
                switch result {
                case let .success(_, T1):
                  let left: Term = .Abstraction(parameter: String(identifier),
                                                parameterType: T1,
                                                body: t2)
                  return (pure(.Application(left: left, right: t1)), context)
                case .failure(_):
                  return (fail("Could not determine type of \(t1)"), context)
                }
            }, context) 
        }, context)
    }
}

// MARK: - Built Ins

fileprivate let builtIn = _builtIn()
fileprivate func _builtIn() -> TermParser {
  return Succ <|> Pred <|> IsZero <|> IfElse <|> Let
}

private let Succ = succ()
private func succ() -> TermParser {
  return (keyword(.SUCC) *> skipSpaces() *> term) >>- { context, t in (pure(.Succ(t)), context) }
}

private let Pred = pred()
private func pred() -> TermParser {
  return (keyword(.PRED) *> skipSpaces() *> term) >>- { context, t in (pure(.Pred(t)), context) }
}

private let IsZero = isZero()
private func isZero() -> TermParser {
  return (keyword(.ISZERO) *> skipSpaces() *> term) >>- { context, t in (pure(.IsZero(t)), context) }
}


// MARK: Context Modifications

fileprivate func shiftContext(context: TermContext,
                              identifier: String.UnicodeScalarView) -> TermContext {
  var context = context
  context.forEach { name, index in
    return context[name] = index + 1
  }
  context[String(identifier)] = 0
  return context
}

fileprivate func unshiftContext(context: TermContext,
                                identifier: String.UnicodeScalarView) -> TermContext {
  var context = context
  context.forEach { name, index in
    if (index != 0) {
      context[name] = index - 1
    }
  }
  context.removeValue(forKey: String(identifier))
  return context
}

// ΜARK: - Keywords

private func keyword(_ word: Keyword) -> StringParser {
  return skipSpaces() *> string(word.rawValue)
}

// ΜARK: - λ

private let LAMBDA = _lambda()
private func _lambda() -> TermParser {
  return (BACKSLASH *> identifier) >>- { context, identifier in

  let context = shiftContext(context: context, identifier: identifier)

  return ((COLON *> type) >>- { context, type in
  return ((PERIOD *> term) >>- { context, t in
      
  let context = unshiftContext(context: context, identifier: identifier)
    
  return (pure(.Abstraction(parameter: String(identifier), parameterType: type, body: t)), context)
  }, context)
  }, context)
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

// MARK: - If Statements

private let IfElse = ifElse()
private func ifElse() -> TermParser {
  return (If *> term) >>- { context, conditional in
  return ((Then *> term) >>- { context, tBranch in
  return ((Else *> term) >>- { context, fBranch in
  return (pure(.If(condition: conditional, trueBranch: tBranch, falseBranch: fBranch)), context)
  }, context)
  }, context)
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

// MARK: - Types

private let baseType = _baseType()
private func _baseType() -> TypeParser {
  return Bool <|> Int <|> Unit <|> (identifier >>- { context, identifier in
    (pure(.base(typeName: String(identifier))), context)
  })
}

private let type = _type()
private func _type() -> TypeParser {
  return chainl1(p: baseType, op: string("->")
    *> pure({ t1, t2 in
      return .function(parameterType: t1, returnType: t2)
    }))
}

fileprivate let Bool = bool()
fileprivate func bool() -> TypeParser {
  return keyword(.BOOL) *> pure(.boolean)
}

fileprivate let Int = int()
fileprivate func int() -> TypeParser {
  return keyword(.INT) *> pure(.integer)
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
    if (Keyword(rawValue: t) != nil) {
      return (fail("Variable was keyword"), context)
    }

    let id = String(t)
    if let index = context[id] {
      return (pure(.Variable(name: id, index: index)), context)
    } else {
      let index = context.count
      return (pure(.Variable(name: id, index: index)), union(context, [id:index]))
    }
  }
}
