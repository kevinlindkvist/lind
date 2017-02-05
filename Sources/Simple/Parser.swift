//
//  TermParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation
import Parswift

fileprivate typealias TermParser = Parser<Term, String.CharacterView, NamingContext>
fileprivate typealias TypeParser = Parser<Type, String.CharacterView, NamingContext>
private typealias StringParser = Parser<String, String.CharacterView, NamingContext>

fileprivate enum Keyword: String {
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
  case OPEN_PAREN = "("
  case CLOSE_PAREN = ")"
  case EQUALS = "="
  // Extensions
  case AS = "as"
  case WILD = "_"
  case LET = "let"
  case IN = "in"
}

private func keyword(_ word: Keyword) -> ParserClosure<String, String.CharacterView, NamingContext> {
  return attempt(parser: spaces *> string(string: word.rawValue))
}

private func succ() -> TermParser {
  return (keyword(.SUCC) *> spaces *> term >>- { t in create(x: .Succ(t)) })()
}

private func pred() -> TermParser {
  return (keyword(.PRED) *> spaces *> term >>- { t in create(x: .Pred(t)) })()
}

private func isZero() -> TermParser {
  return (keyword(.ISZERO) *> spaces *> term >>- { t in create(x: .IsZero(t)) })()
}

// MARK: Context Modifications

private func shiftContext(name: String) -> (NamingContext) -> NamingContext {
  return { context in
    var newContext: NamingContext = [:]
    context.forEach { existingName, index in
      newContext[existingName] = index + 1
    }
    newContext[name] = 0
    return newContext
  }
}

private func unshiftContext(name: String) -> (NamingContext) -> NamingContext {
  return { context in
    var newContext: NamingContext = [:]
    context.forEach { existingName, index in
      if (existingName != name) {
        newContext[existingName] = index - 1
      }
    }
    return newContext
  }
}

private func addToContext(name: String) -> (NamingContext) -> NamingContext {
  return { state in
      if state[name] != nil {
        return state
      }
      var newState = state
      newState[name] = state.count
      return newState
  }
}

// MARK: - Types

private func baseType() -> TypeParser {
  return (bool <|> int <|> unitType <|> identifier >>- { identifier in
    create(x: .Base(identifier))
    })()
}

private func type() -> TypeParser {
  return (chainl1(parser: baseType,
                  oper: string(string: "->") *> create(x: { t1, t2 in .Function(t1, t2) })))()
}

fileprivate func bool() -> TypeParser {
  return (keyword(.BOOL) *> create(x: .Bool))()
}

fileprivate func int() -> TypeParser {
  return (keyword(.INT) *> create(x: .Integer))()
}

fileprivate func unitType() -> TypeParser {
  return (keyword(.UNIT) *> create(x: .Unit))()
}

// MARK: - Values

fileprivate func value() -> TermParser {
  return (True <|> False <|> zero <|> unit <|> lambda <|> variable)()
}

private func unit() -> TermParser {
  return (keyword(.UNIT) *> create(x: .Unit))()
}

private func True() -> TermParser {
  return (keyword(.TRUE) *> create(x: .True))()
}

private func False() -> TermParser {
  return (keyword(.FALSE) *> create(x: .False))()
}

fileprivate func zero() -> TermParser {
  return (keyword(.ZERO) *> create(x: .Zero))()
}

// MARK: - Variables

private func identifier() -> Parser<String, String.CharacterView, NamingContext> {
  return (spaces *> many1(parser: alphanumeric) >>- { x in
    return create(x: String(x))
    })()
}

private func variable() -> TermParser {
  return (identifier >>- { name in
    if (Keyword(rawValue: name) != nil) {
      return fail(message: "Variable \"\(name)\" is keyword")
    }
    return modifyState(f: addToContext(name: name)) *> userState >>- { state in
      let index = state[name]!
      return create(x: .va(name, index))
    }
  })()
}

// MARK: - If Statements

private func ifElse() -> TermParser {
  return (If *> term >>- { conditional in
    return Then *> term >>- { tBranch in
      return Else *> term >>- { fBranch in
        return create(x: .If(conditional, tBranch, fBranch))
      }
    }
    })()
}

fileprivate func If() -> StringParser {
  return keyword(.IF)()
}

fileprivate func Then() -> StringParser {
  return keyword(.THEN)()
}

fileprivate func Else() -> StringParser {
  return keyword(.ELSE)()
}

// ΜARK: - λ

private func lambda() -> TermParser {
  // Parse the parameter name.
  return (keyword(.BACKSLASH) *> identifier >>- { name in
    // Parse the type annotation of the parameter.
    return modifyState(f: shiftContext(name: name)) *> keyword(.COLON) *> type >>- { argumentType in
      // Parse the body.
      return keyword(.PERIOD) *> term >>- { body in
        // Unshift the state after parsing the body.
        return  modifyState(f: unshiftContext(name: name)) *> create(x: .abs(name, argumentType, body))
      }
    }
  })()
}

fileprivate func period() -> StringParser {
  return keyword(.PERIOD)()
}

fileprivate func colon() -> StringParser {
  return keyword(.COLON)()
}

fileprivate func backslash() -> StringParser {
  return keyword(.BACKSLASH)()
}

// MARK: - Built Ins

fileprivate func builtIn() -> TermParser {
  return (succ <|> pred <|> isZero <|> ifElse <|> Let)()
}

// MARK: - Atoms

private func atom() -> TermParser {
  return ((keyword(.OPEN_PAREN) *> sequence <* keyword(.CLOSE_PAREN)) <|> builtIn <|> value)()
}

// MARK: - Ascription

fileprivate func ascription() -> TypeParser {
  return (As *> type)()
}

fileprivate func As() -> StringParser {
  return keyword(.AS)()
}

// MARK: - Assignment

fileprivate func Let() -> TermParser {
  // Let is a slightly different derived form in that it actually runs
  // the typechecker to verify the statement.
  return (keyword(.LET) *> identifier >>- { identifier in
    return keyword(.EQUALS) *> term >>- { t1 in
      return keyword(.IN) *> term >>- { t2 in
        // Verify the type of t1 before passing it to t2.
        if let type1 = typeOf(t: t1, context: [:]) {
          let left: Term = .abs(identifier, type1, t2)
          return create(x: .app(left, t1))
        } else {
          return fail(message: "Could not determine type of \(t1)")
        }
      }
    }
    })()
}

// MARK: - Program

private func sequence() -> TermParser {
  return chainl1(parser: term,
                 oper: (spaces *> string(string: ";") <* spaces)
                  *> create(x: { t1, t2 in return .app(.abs("_", .Unit, t2), t1) }))()
}

private func term() -> TermParser {
  return chainl1(parser: nonAppTerm,
                 oper: string(string: " ") *> create(x: { t1, t2 in .app(t1, t2) }))()
}

private func nonAppTerm() -> TermParser {
  return (atom >>- { term in
    // After an atom is parsed, check if there is an ascription, otherwise purely return the atom.
    return (ascription >>- { type in
      return create(x: .app(.abs("_", type, .va("_", 0)), term)) })
      <|> create(x: term)
  })()
}

public func parse(input: String) -> Either<ParseError, Term> {
  return parse(input: input.characters, with: sequence, userState: [:], fileName: "")
}

