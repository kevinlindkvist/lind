//
//  Lindterpreter.swift
//  lind
//
//  Created by Kevin Lindkvist on 11/23/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import lind
import Foundation
import Result

public typealias Evaluation = Result<((Term, Type), NamingContext, TypeContext), EvaluationError>

public func description(evaluation: Evaluation) -> String {
  switch evaluation {
    case let .Success((term, type), _, _): return term.description + " :: " + type.description
    case let .failure(message): return message.description
  }
}

func evaluate(input: String,
              terms: TermContext = [:],
              types: TypeContext = [:]) -> Evaluation {
  switch parse(input: input, terms: terms) {
  case let .Success(result):
    switch typeOf(term: result.1, context: types) {
      case let .Success(_, type):
        let evaluatedTerm = evaluate(term: result.1)
        return .Success(((evaluatedTerm, type), terms, types))
      case let .failure(error):
        return .failure(.typeError(error))
    }
  case let .failure(error):
    return .failure(.parseError(error))
  }
}
