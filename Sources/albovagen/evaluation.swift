//
//  Lindterpreter.swift
//  lind
//
//  Created by Kevin Lindkvist on 11/23/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import Result
import FullSimple

public typealias Evaluation = Result<((Term, Type), [String:Int], TypeContext), EvaluationError>

public func description(evaluation: Evaluation) -> String {
  switch evaluation {
    case let .success((term, type), _, _): return term.description + " :: " + type.description
    case let .failure(message): return message.description
  }
}

func evaluate(input: String,
              terms: TermContext = [:],
              types: TypeContext = [:]) -> Evaluation {
  switch parse(input: input, terms: terms) {
  case let .right(result):
    switch typeOf(term: result, context: types) {
      case let .success(_, type):
        let evaluatedTerm = evaluate(term: result)
        return .success(((evaluatedTerm, type), terms, types))
      case let .failure(error):
        return .failure(.typeError(error))
    }
  case let .left(error):
    return .failure(.parseError(error))
  }
}
