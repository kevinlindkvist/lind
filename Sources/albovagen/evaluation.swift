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

public typealias Evaluation = Either<EvaluationError, (Term, Type, ParseContext)>

public func description(evaluation: Evaluation) -> String {
  switch evaluation {
    case let .right(term, type, context): return term.description + " :: " + type.description + "\n\(context)"
    case let .left(message): return message.description
  }
}

func evaluate(input: String, context: ParseContext) -> Evaluation {
  switch parse(input: input, context: context) {
  case let .right(result, updatedContext):
    switch typeOf(term: result, parsedContext: updatedContext) {
      case let .right(_, type):
        let evaluatedTerm = evaluate(term: result, namedTerms: updatedContext.namedTerms)
        return .right(evaluatedTerm, type, updatedContext)
      case let .left(error):
        return .left(.typeError(error))
    }
  case let .left(error):
    return .left(.parseError(error))
  }
}
