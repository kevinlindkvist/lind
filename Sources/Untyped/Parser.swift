//
//  UntypedLambdaCalculusParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import Foundation
import Parswift

private typealias NamingContext = [String: Int]
private typealias TermParser = Parser<Term, String.CharacterView, NamingContext>

private func identifier() -> Parser<String, String.CharacterView, NamingContext> {
  return (many1(parser: alphanumeric) >>- { create(x: String($0)) })()
}

private func add(name: String) -> (NamingContext) -> NamingContext {
  return { context in
    if context[name] != nil {
      return context
    }

    var newContext = context
    newContext[name] = context.count
    return newContext
  }
}

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

private func variable() -> TermParser {
  return (identifier >>- { name in modifyState(f: add(name: name)) *> userState >>- { x in
    let i = x[name]!
    return create(x: .va(name, i))
    }})()
}

private func lambda() -> TermParser {
  return ((string(string: "\\") *> identifier)
    >>- { name in modifyState(f: shiftContext(name: name)) *> (string(string: ".") *> term)
      >>- { t in create(x: .abs(name, t)) } <* modifyState(f: unshiftContext(name: name))})()
}

private func nonAppTerm() -> TermParser {
  return ((string(string: "(") *> term <* string(string: ")")) <|> lambda <|> variable)()
}

private func term() -> TermParser {
  return chainl1(parser: nonAppTerm,
                 oper: string(string: " ") *> create(x: { t1, t2 in .app(t1, t2)}))()
}

private func untypedLambdaCalculus() -> TermParser {
  return term()
}

func parseUntypedLambdaCalculus(_ str: String) -> Either<ParseError, Term> {
  return parse(input: str.characters, with: untypedLambdaCalculus, userState: [:], fileName: "")
}
