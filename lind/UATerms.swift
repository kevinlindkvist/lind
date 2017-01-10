//
//  UntypedArithmeticUATerms.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

public indirect enum UATerm {
  case True
  case False
  case If(IfElseUATerm)
  case Zero
  case Succ(UATerm)
  case Pred(UATerm)
  case IsZero(UATerm)
}

extension UATerm: Equatable {
}

public func ==(lhs: UATerm, rhs: UATerm) -> Bool {
  switch (lhs, rhs) {
  case (.True, .True):
    return true
  case (.False, .False):
    return true
  case (let .If(left), let .If(right)):
    return left == right
  case (.Zero, .Zero):
    return true
  case (let .Succ(left), let .Succ(right)):
    return left == right
  case (let .Pred(left), let .Pred(right)):
    return left == right
  case (let .IsZero(left), let .IsZero(right)):
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
