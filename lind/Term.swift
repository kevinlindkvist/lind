//
//  Term.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public indirect enum Term {
  case unit
  case abstraction(parameter: String, parameterType: Type, body: Term)
  case application(left: Term, right: Term)
  case tmTrue
  case tmFalse
  case ifElse(condition: Term, trueBranch: Term, falseBranch: Term)
  case zero
  case isZero(Term)
  case succ(Term)
  case pred(Term)
  case variable(name: String, index: Int)
}

public typealias TermContext = [String:Int]

extension Term: CustomStringConvertible {
  public var description: String {
    switch self {
      case .tmTrue:
        return "true"
      case .tmFalse:
        return "false"
      case let .ifElse(t1, t2, t3):
        return "if (\(t1))\n\tthen (\(t2))\n\telse (\(t3))"
      case .zero:
        return "0"
      case let .succ(t):
        return "succ(\(t))"
      case let .pred(t):
        return "pred(\(t))"
      case let .isZero(t):
        return "isZero(\(t))"
      case let .variable(name, _):
        return "\(name)"
      case let .abstraction(parameter, type, body):
        return "\\\(parameter):\(type).(\(body))"
      case let .application(lhs, rhs):
        return "\(lhs) \(rhs)"
      case .unit:
        return "unit"
    }
  }
}

extension Term: Equatable {
}

public func ==(lhs: Term, rhs: Term) -> Bool {
  switch (lhs, rhs) {
  case (.tmTrue, .tmTrue):
    return true
  case (.tmFalse, .tmFalse):
    return true
  case (.zero, .zero):
    return true
  case let (.succ(t1), .succ(t2)):
    return t1 == t2
  case let (.pred(t1), .pred(t2)):
    return t1 == t2
  case let (.isZero(t1), .isZero(t2)):
    return t1 == t2
  case let (.ifElse(t1,t2,t3), .ifElse(t11, t22, t33)):
    return t1 == t11 && t2 == t22 && t3 == t33
  case let (.variable(leftName, leftIndex), .variable(rightName, rightIndex)):
    return leftName == rightName && leftIndex == rightIndex
  case let (.abstraction(leftValue), .abstraction(rightValue)):
    return leftValue == rightValue
  case let (.application(leftValue), .application(rightValue)):
    return leftValue == rightValue
  case (.unit, .unit):
    return true
  default:
    return false
  }
}
