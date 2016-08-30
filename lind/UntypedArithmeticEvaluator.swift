//
//  UntypedArithmeticEvaluator.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

func evaluateUntypedArithmetic(ts: [Term]) -> [Term] {
  return ts.map { evaluateUntypedArithmetic($0) }
}

private func evaluateUntypedArithmetic(t: Term) -> Term {
  switch t {
  case let .ifElse(ifElseTerm):
    switch evaluateUntypedArithmetic(ifElseTerm.conditional) {
    case .tmTrue:
      return evaluateUntypedArithmetic(ifElseTerm.trueBranch)
    case .tmFalse:
      return evaluateUntypedArithmetic(ifElseTerm.falseBranch)
    default:
      assert(false)
      return .tmFalse
    }
  case .succ(.zero):
    return .succ(.zero)
  case let .succ(succTerm):
    let evaluatedTerm = evaluateUntypedArithmetic(succTerm)
    return evaluateUntypedArithmetic(.succ(evaluatedTerm))
  case .pred(.zero):
    return .zero
  case let .pred(.succ(succTerm)):
    return succTerm
  case let .pred(predTerm):
    let evaluatedTerm = evaluateUntypedArithmetic(predTerm)
    return evaluateUntypedArithmetic(.pred(evaluatedTerm))
  case .isZero(.zero):
    return .tmTrue
  case .isZero(.succ(_)):
    return .tmFalse
  case let .isZero(zeroTerm):
    let evaluatedTerm = evaluateUntypedArithmetic(zeroTerm)
    return evaluateUntypedArithmetic(.isZero(evaluatedTerm))
  case .tmTrue: return .tmTrue
  case .tmFalse: return .tmFalse
  case .zero: return .zero
  }
}