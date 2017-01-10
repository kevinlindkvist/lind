//
//  UntypedArithmeticEvaluator.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

func evaluateUntypedArithmetic(_ t: UATerm) -> UATerm {
  switch t {
  case let .If(ifElseTerm):
    switch evaluateUntypedArithmetic(ifElseTerm.conditional) {
    case .True:
      return evaluateUntypedArithmetic(ifElseTerm.trueBranch)
    case .False:
      return evaluateUntypedArithmetic(ifElseTerm.falseBranch)
    default:
      assert(false)
      return .False
    }
  case .Succ(.Zero):
    return .Succ(.Zero)
  case let .Succ(succTerm):
    let evaluatedTerm = evaluateUntypedArithmetic(succTerm)
    return evaluateUntypedArithmetic(.Succ(evaluatedTerm))
  case .Pred(.Zero):
    return .Zero
  case let .Pred(.Succ(succTerm)):
    return succTerm
  case let .Pred(predTerm):
    let evaluatedTerm = evaluateUntypedArithmetic(predTerm)
    return evaluateUntypedArithmetic(.Pred(evaluatedTerm))
  case .IsZero(.Zero):
    return .True
  case .IsZero(.Succ(_)):
    return .False
  case let .IsZero(zeroTerm):
    let evaluatedTerm = evaluateUntypedArithmetic(zeroTerm)
    return evaluateUntypedArithmetic(.IsZero(evaluatedTerm))
  case .True: return .True
  case .False: return .False
  case .Zero: return .Zero
  }
}
