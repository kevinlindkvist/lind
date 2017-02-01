//
//  UntypedArithmeticTerms.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

public indirect enum Term {
  case True
  case False
  case If(IfElseTerm)
  case Zero
  case Succ(Term)
  case Pred(Term)
  case IsZero(Term)
}

extension Term: Equatable {
}

public func ==(lhs: Term, rhs: Term) -> Bool {
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
