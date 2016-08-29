//
//  UntypedArithmeticTerms.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

public indirect enum Term {
  case tmTrue
  case tmFalse
  case ifElse(IfElseTerm)
  case zero
  case succ(Term)
  case pred(Term)
  case isZero(Term)
}

extension Term: Equatable {
}

public func ==(lhs: Term, rhs: Term) -> Bool {
  switch (lhs, rhs) {
  case (.tmTrue, .tmTrue):
    return true
  case (.tmFalse, .tmFalse):
    return true
  case (let .ifElse(left), let .ifElse(right)):
    return left == right
  case (.zero, .zero):
    return true
  case (let .succ(left), let .succ(right)):
    return left == right
  case (let .pred(left), let .pred(right)):
    return left == right
  case (let .isZero(left), let .isZero(right)):
    return left == right
  default:
    return false
  }
}

public struct IfElseTerm {
  let conditional: Term
  let trueBranch: Term
  let falseBranch: Term

  var description: String {
    return "if \n\t\(conditional)\nthen\n\t\(trueBranch)\nelse\n\t\(trueBranch)"
  }
}

extension IfElseTerm: Equatable {
}

public func ==(lhs: IfElseTerm, rhs: IfElseTerm) -> Bool {
  return (lhs.conditional == rhs.conditional) && (lhs.trueBranch == rhs.trueBranch) && (lhs.falseBranch == rhs.falseBranch)
}