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

public typealias Evaluation = Result<(Term, NamingContext, TypeContext), EvaluationError>

public func description(evaluation: Evaluation) -> String {
  switch evaluation {
    case let .success(term, _, _): return term.description
    case let .failure(message): return message.description
  }
}

func evaluate(input: String,
              terms: TermContext = [:],
              types: TypeContext = [:]) -> Evaluation {
  switch parse(input: input, terms: terms) {
  case let .success(result):
    switch typeOf(term: result.1, context: types) {
      case .success(_, _):
        return .success((result.1, terms, types))
      case let .failure(error):
        return .failure(.typeError(error))
    }
  case let .failure(error):
    return .failure(.parseError(error))
  }
}
