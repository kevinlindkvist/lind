//
//  UntypedArithmeticUATerms.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

public indirect enum UATerm {
  case tmTrue
  case tmFalse
  case ifElse(IfElseUATerm)
  case zero
  case succ(UATerm)
  case pred(UATerm)
  case isZero(UATerm)
}

extension UATerm: Equatable {
}

public func ==(lhs: UATerm, rhs: UATerm) -> Bool {
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

public struct IfElseUATerm {
  let conditional: UATerm
  let trueBranch: UATerm
  let falseBranch: UATerm

  var description: String {
    return "if \n\t\(conditional)\nthen\n\t\(trueBranch)\nelse\n\t\(trueBranch)"
  }
}

extension IfElseUATerm: Equatable {
}

public func ==(lhs: IfElseUATerm, rhs: IfElseUATerm) -> Bool {
  return (lhs.conditional == rhs.conditional) && (lhs.trueBranch == rhs.trueBranch) && (lhs.falseBranch == rhs.falseBranch)
}
