//
//  Lindterpreter.swift
//  lind
//
//  Created by Kevin Lindkvist on 11/23/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import Parswift
import FullSimple

public typealias Evaluation = Either<EvaluationError, (Term, Type)>

public func description(evaluation: Evaluation) -> String {
  switch evaluation {
    case let .right(term, type): return term.description + " :: " + type.description
    case let .left(message): return message.description
  }
}

func evaluate(input: String,
              terms: TermContext = [:],
              types: TypeContext = [:]) -> Evaluation {
  switch parse(input: input, terms: ParseContext(terms: [:], types: [:], namedTypes: [:], namedTerms: [])) {
  case let .right(result, _):
    switch typeOf(term: result, context: types) {
      case let .right(_, type):
        let evaluatedTerm = evaluate(term: result)
        return .right(evaluatedTerm, type)
      case let .left(error):
        return .left(.typeError(error))
    }
  case let .left(error):
    return .left(.parseError(error))
  }
}
