//
//  LindParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation
import Parswift

fileprivate enum Keyword: String {
  // Built ins
  case IF = "if"
  case THEN = "then"
  case ELSE = "else"
  case SUCC = "succ"
  case PRED = "pred"
  case ISZERO = "isZero"
  case FIX = "fix"
  case LETREC = "letrec"
  // Values
  case ZERO = "0"
  case UNIT = "unit"
  case FALSE = "false"
  case TRUE = "true"
  // Base Types
  case BOOL = "bool"
  case INT = "int"
  case ARROW = "->"
  // Special characters
  case COLON = ":"
  case PERIOD = "."
  case COMMA = ","
  case BACKSLASH = "\\"
  case OPEN_TUPLE = "{"
  case CLOSE_TUPLE = "}"
  case OPEN_PAREN = "("
  case CLOSE_PAREN = ")"
  case OPEN_ANGLE = "<"
  case CLOSE_ANGLE = ">"
  case EQUALS = "="
  case BAR = "|"
  // Extensions
  case AS = "as"
  case WILD = "_"
  case LET = "let"
  case IN = "in"
  case CASE = "case"
  case OF = "of"
  case CASE_ARROW = "=>"
}

private typealias TermParser = Parser<Term, String.CharacterView, TermContext>
private typealias TypeParser = Parser<Type, String.CharacterView, TermContext>
private typealias StringParser = Parser<String, String.CharacterView, TermContext>
private typealias TypeBindingParser = Parser<(String, Type), String.CharacterView, TermContext>

public func parse(input: String, terms: TermContext) -> Either<ParseError, Term> {
  return parse(input: input.characters, with: lind, userState: terms, fileName: "")
}

public func parseBinding(input: String) -> Either<ParseError, (String, Type)> {
  return parse(input: input.characters, with: abbreviation, userState: [:], fileName: "")
}

private func lind() -> TermParser {
  return (sequence <* endOfInput)()
}

private func sequence() -> TermParser {
  return chainl1(parser: term,
                 oper: (spaces *> string(string: ";") <* spaces)
                  *> create(x: { t1, t2 in
                    let abstraction: Term = .Abstraction(parameter: "_",
                                                         parameterType: .Unit,
                                                         body: t2)
                    return .Application(left: abstraction, right: t1)
                  }))()
}

private func term() -> TermParser {
  return chainl1(parser: nonApplicationTerm,
                 oper: string(string: " ") *> spaces *> create(x: { t1, t2 in .Application(left: t1, right: t2) }))()
}

private func nonApplicationTerm() -> TermParser {
  return (atom >>- { term in
    // After an atom is parsed, check if there is an ascription.
    return ascription >>- { type in
      let body: Term = .Variable(name: "x", index: 0)
      let abstraction: Term = .Abstraction(parameter: "x", parameterType: type, body: body)
      return create(x: .Application(left: abstraction, right: term))
      }
      // Check for a projection if there was no ascription.
      <|> projection(term: term)
      // If no projection or ascription, return the atom.
      <|> create(x: term)
    })()
}

private func projection(term: Term) -> () -> TermParser {
  return keyword(.PERIOD) *> separate(parser: identifier, by: keyword(.PERIOD)) >>- { identifiers in
    var term = term
    identifiers.forEach { projection in
      let pattern: Pattern = .Record([projection:.Variable(name: "x")])
      term = .Let(pattern: pattern, argument: term, body: .Variable(name: "x", index: 0))
    }
    return create(x: term)
  }
}

// MARK: - Abbreviations

private func abbreviation() -> TypeBindingParser {
  return (identifier >>- { name in type >>- { type in create(x: (name, type)) }})()
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
  return (keyword(.LET) *> pattern >>- { letPattern in
    return keyword(.EQUALS) *> term >>- { t1 in
      return userState >>- { savedContext in
        return modifyState(f: shiftContext(pattern: letPattern)) *> keyword(.IN) *> term >>- { t2 in
          return modifyState(f: { _ in savedContext}) *> create(x: .Let(pattern: letPattern, argument: t1, body: t2))
        }
      }
    }
    })()
}


// MARK: Patterns

private func pattern() -> Parser<Pattern, String.CharacterView, TermContext> {
  return (attempt(parser: identifier >>- { name in create(x: .Variable(name: name)) })
    <|> (keyword(.OPEN_TUPLE) *>
      separate(parser: patternEntry,
               byAtLeastOne: keyword(.COMMA)) >>- { contents in
                var values: [String:Pattern] = [:]
                var counter = 1
                contents.forEach {
                  if $0.0 == "" {
                    values[String(counter)] = $0.1
                  } else {
                    values[$0.0] = $0.1
                  }
                  counter = counter + 1
                }
                return create(x: .Record(values))
      }
      <* keyword(.CLOSE_TUPLE)))()
}

fileprivate func patternEntry() -> Parser<(String, Pattern), String.CharacterView, TermContext> {
  return (
    attempt(parser: identifier >>- { name in keyword(.COLON) *> pattern >>- { p in create(x: (name, p)) } })
      <|> attempt(parser: pattern >>- { p in create(x: ("", p)) })
    )()
}

// MARK: - Built Ins

fileprivate func builtIn() -> TermParser {
  return (fix <|> succ <|> pred <|> isZero <|> ifElse <|> Let <|> variantCase)()
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

private func fix() -> TermParser {
  return ((keyword(.FIX) *> term >>- { t in create(x: .Fix(t)) })
    // The derived convenience form of fix.
    <|> keyword(.LETREC) *> identifier <* keyword(.COLON) >>- { name in
      return type >>- { termType in
        return keyword(.EQUALS) *> term >>- { t in
          return keyword(.IN) *> term >>- { body in
            let derivedTerm: Term = .Fix(.Abstraction(parameter: "x", parameterType: termType, body: t))
            return create(x: .Let(pattern: .Variable(name: name), argument: derivedTerm, body: body))
          }
        }
      }
    }
  )()
}


// MARK: Context Modifications

private func shiftContext(name: String) -> (TermContext) -> TermContext {
  return { context in
    var newContext: TermContext = [:]
    context.forEach { existingName, index in
      newContext[existingName] = index + 1
    }
    newContext[name] = 0
    return newContext
  }
}

private func shiftContext(pattern: Pattern) -> (TermContext) -> TermContext {
  return { context in
    var newContext: TermContext = [:]
    context.forEach { existingName, index in
      newContext[existingName] = index + 1
    }
    for (index, patternVariable) in pattern.variables.enumerated() {
      newContext[patternVariable] = index
    }
    return newContext
  }
}

private func addToContext(name: String) -> (TermContext) -> TermContext {
  return { state in
    if state[name] != nil {
      return state
    }
    var newState = state
    newState[name] = state.count
    return newState
  }
}

// ΜARK: - Keywords

private func keyword(_ word: Keyword) -> ParserClosure<String, String.CharacterView, TermContext> {
  return attempt(parser: spaces *> string(string: word.rawValue))
}

// ΜARK: - λ

private func lambda() -> TermParser {
  // Parse the parameter name.
  return (keyword(.BACKSLASH) *> (identifier <|> keyword(.WILD)) >>- { name in
    // Parse the type annotation of the parameter.
    return userState >>- { savedContext in
      return modifyState(f: shiftContext(name: name)) *> keyword(.COLON) *> type >>- { argumentType in
        // Parse the body.
        return keyword(.PERIOD) *> term >>- { body in
          // Unshift the state after parsing the body.
          return  modifyState(f: { _ in savedContext}) *> create(x: .Abstraction(parameter: name, parameterType: argumentType, body: body))
        }
      }
    }
    })()
}

// MARK: - If Statements

private func ifElse() -> TermParser {
  return (If *> term >>- { conditional in
    return Then *> term >>- { tBranch in
      return Else *> term >>- { fBranch in
        return create(x: .If(condition: conditional, trueBranch: tBranch, falseBranch: fBranch))
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

// MARK: - Types

private func baseType() -> TypeParser {
  return (bool <|> int <|> unitType <|> productType <|> sumType <|> identifier >>- { typeName in
    create(x: .Base(typeName: typeName))
    })()
}

fileprivate func sumType() -> TypeParser {
  return (keyword(.OPEN_ANGLE) *> separate(parser: productEntry, byAtLeastOne: keyword(.COMMA)) >>- { contents in
      var values: [String:Type] = [:]
      var counter = 1
      contents.forEach {
        if $0.0 == "" {
          values[String(counter)] = $0.1
        } else {
          values[$0.0] = $0.1
        }
        counter = counter + 1
      }
      return create(x: .Sum(values))
    }
    <* keyword(.CLOSE_ANGLE))()
}

fileprivate func productType() -> TypeParser {
  return (keyword(.OPEN_TUPLE) *>
    separate(parser: productEntry, by: keyword(.COMMA)) >>- { contents in
      var values: [String:Type] = [:]
      var counter = 1
      contents.forEach {
        if $0.0 == "" {
          values[String(counter)] = $0.1
        } else {
          values[$0.0] = $0.1
        }
        counter = counter + 1
      }
      return create(x: .Product(values))
    }
    <* keyword(.CLOSE_TUPLE))();
}

fileprivate func productEntry() -> Parser<(String, Type), String.CharacterView, TermContext> {
  return (attempt(parser: identifier >>- { name in keyword(.COLON) *> type >>- { t in create(x: (name, t)) } })
    <|> attempt(parser: type >>- { t in create(x: ("", t)) }))()
}

private func type() -> TypeParser {
  return chainl1(parser: baseType, oper: keyword(.ARROW) *> create(x: { t1, t2 in .Function(parameterType: t1, returnType: t2)}))()
}

fileprivate func bool() -> TypeParser {
  return (keyword(.BOOL) *> create(x: .Boolean))()
}

fileprivate func int() -> TypeParser {
  return (keyword(.INT) *> create(x: .Integer))()
}

fileprivate func unitType() -> TypeParser {
  return (keyword(.UNIT) *> create(x: .Unit))()
}

// MARK: - Values

fileprivate func value() -> TermParser {
  return (True <|> False <|> zero <|> unit <|> lambda <|> tuple <|> tag <|> variable)()
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

fileprivate func tuple() -> TermParser {
  return (keyword(.OPEN_TUPLE) *>
    separate(parser: tupleEntry, by: keyword(.COMMA)) >>- { contents in
      var values: [String:Term] = [:]
      var counter = 1
      contents.forEach {
        if $0.0 == "" {
          values[String(counter)] = $0.1
        } else {
          values[$0.0] = $0.1
        }
        counter = counter + 1
      }
      return create(x: .Tuple(values))
    }
    <* keyword(.CLOSE_TUPLE))();
}

fileprivate func tupleEntry() -> Parser<(String, Term), String.CharacterView, TermContext> {
  return (attempt(parser: identifier >>- { name in keyword(.COLON) *> term >>- { t in create(x: (name, t)) } })
    <|> attempt(parser: term >>- { t in create(x: ("", t)) }))()
}


// MARK: - Variables

private func identifier() -> Parser<String, String.CharacterView, TermContext> {
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
      return create(x: .Variable(name: name, index: index))
    }
    })()
}

// MARK: Variants

private func tag() -> TermParser {
  return (keyword(.OPEN_ANGLE) *> identifier >>- { name in
    return keyword(.EQUALS) *> term >>- { t in
      return keyword(.CLOSE_ANGLE) *> ascription >>- { ascribedType in
        return create(x: .Tag(label: name, term: t, ascribedType: ascribedType))
      }
    }
  })()
}

private func variantCase() -> TermParser {
  return (keyword(.CASE) *> term >>- { t in
    return keyword(.OF) *> separate(parser: caseStatement, byAtLeastOne: keyword(.BAR)) >>- { cases in
      var taggedCases: [String:Case] = [:]
      cases.forEach { taggedCases[$0.label] = $0 }
      return create(x: .Case(term: t, cases: taggedCases))
    }
  })()
}

private func caseStatement() -> Parser<Case, String.CharacterView, TermContext> {
  return (keyword(.OPEN_ANGLE) *> identifier >>- { label in
    return keyword(.EQUALS) *> identifier >>- { parameter in
      return keyword(.CLOSE_ANGLE) *> keyword(.CASE_ARROW) *> userState >>- { savedContext in
        return modifyState(f: shiftContext(name: parameter)) *> term >>- { t in
          return modifyState(f: { _ in savedContext}) *> create(x: Case(label: label, parameter: parameter, term: t))
        }
      }
    }
    })()
}
