//
//  Term.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public indirect enum Term {
  case Unit
  case Abstraction(parameter: String, parameterType: Type, body: Term)
  case Application(left: Term, right: Term)
  case True
  case False
  case If(condition: Term, trueBranch: Term, falseBranch: Term)
  case Zero
  case IsZero(Term)
  case Succ(Term)
  case Pred(Term)
  case Variable(name: String, index: Int)
  case Tuple([String:Term])
  case Projection(collection: Term, index: String)
}

public typealias TermContext = [String:Int]

extension Term: CustomStringConvertible {
  public var description: String {
    switch self {
      case .True:
        return "true"
      case .False:
        return "false"
      case let .If(t1, t2, t3):
        return "if (\(t1))\n\tthen (\(t2))\n\telse (\(t3))"
      case .Zero:
        return "0"
      case let .Succ(t):
        return "succ(\(t))"
      case let .Pred(t):
        return "pred(\(t))"
      case let .IsZero(t):
        return "isZero(\(t))"
      case let .Variable(name, _):
        return "\(name)"
      case let .Abstraction(parameter, type, body):
        return "\\\(parameter):\(type).(\(body))"
      case let .Application(lhs, rhs):
        return "\(lhs) \(rhs)"
      case .Unit:
        return "unit"
      case let .Tuple(values):
        return values.description
      case let .Projection(collection, subs):
        return "\(collection).\(subs)"
    }
  }
}

extension Term: Equatable {
}

public func ==(lhs: Term, rhs: Term) -> Bool {
  switch (lhs, rhs) {
  case (.True, .True):
    return true
  case (.False, .False):
    return true
  case (.Zero, .Zero):
    return true
  case let (.Succ(t1), .Succ(t2)):
    return t1 == t2
  case let (.Pred(t1), .Pred(t2)):
    return t1 == t2
  case let (.IsZero(t1), .IsZero(t2)):
    return t1 == t2
  case let (.If(t1,t2,t3), .If(t11, t22, t33)):
    return t1 == t11 && t2 == t22 && t3 == t33
  case let (.Variable(leftName, leftIndex), .Variable(rightName, rightIndex)):
    return leftName == rightName && leftIndex == rightIndex
  case let (.Abstraction(leftValue), .Abstraction(rightValue)):
    return leftValue == rightValue
  case let (.Application(leftValue), .Application(rightValue)):
    return leftValue == rightValue
  case (.Unit, .Unit):
    return true
  default:
    return false
  }
}
