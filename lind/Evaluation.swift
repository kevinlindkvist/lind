//
//  Evaluation.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/25/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public func evaluate(term: Term) -> Term {
  return evaluate(term: term, context: [:])
}

private func evaluate(term: Term, context: NamingContext) -> Term {
  switch term {
  case .unit: return .unit
  // Application and abstraction
  case .abstraction(_,_,_):
    return term

  case let .application(.abstraction(_, _, body), v2) where isValue(term: v2):
    let t2 = termSubstop(v2, body)
    return evaluate(term: t2, context: context)

  case let .application(v1, t2) where isValue(term: v1):
    let t2p = evaluate(term: t2, context: context)
    return .application(left: v1, right: t2p)

  case let .application(t1, t2):
    let t1p = evaluate(term: t1, context: context)
    return .application(left: t1p, right: t2)
  // Numbers
  case .zero: return .zero
    
  case .isZero(.zero):
    return .tmTrue
  case .isZero(.succ(_)):
    return .tmFalse
  case let .isZero(zeroTerm):
    let evaluatedTerm = evaluate(term: zeroTerm, context: context)
    return evaluate(term: .isZero(evaluatedTerm), context: context)

  case .succ(.zero):
    return .succ(.zero)
  case let .succ(succTerm):
    return .succ(evaluate(term: succTerm, context: context))
    
  case .pred(.zero):
    return .zero
  case let .pred(.succ(succTerm)):
    return succTerm
  case let .pred(predTerm):
    let evaluatedTerm = evaluate(term: predTerm, context: context)
    return evaluate(term: .pred(evaluatedTerm), context: context)
    
  // Booleans
  case .tmTrue: return .tmTrue
  case .tmFalse: return .tmFalse

  case let .ifElse(conditional, trueBranch, falseBranch):
    switch evaluate(term: conditional, context: context) {
      case .tmTrue:
        return evaluate(term: trueBranch, context: context)
      default:
        return evaluate(term: falseBranch, context: context)
    }
  // Variables
  case .variable(_, _):
    return term
  }
}

private func isValue(term: Term) -> Bool {
  switch term {
    case .abstraction: return true
    case .unit: return true
    case .tmTrue: return true
    case .tmFalse: return true
    default: return isNumericValue(term: term)
  }
}

private func isNumericValue(term: Term) -> Bool {
  switch term {
  case let .succ(t) where isNumericValue(term: t):
    return true
  case .zero:
    return true
  default:
    return false
  }
}

private func shift(_ d: Int, _ c: Int, _ t: Term) -> Term {
  switch t {
    case let .variable(name, index) where index < c:
      return .variable(name: name, index: index)
    case let .variable(name, index):
      return .variable(name: name, index: index+d)
    case let .abstraction(name, type, body):
      return .abstraction(parameter: name, parameterType: type, body: shift(d, c+1, body))
    case let .application(lhs, rhs):
      return .application(left: shift(d, c, lhs), right: shift(d, c, rhs))
    case let .ifElse(conditional, trueBranch, falseBranch):
      return .ifElse(condition: shift(d, c, conditional),
                     trueBranch: shift(d, c, trueBranch),
                     falseBranch: shift(d, c, falseBranch))
    case let .succ(body):
      return .succ(shift(d, c, body))
    case let .pred(body):
      return .pred(shift(d, c, body))
    case let .isZero(body):
      return .isZero(shift(d, c, body))
    default:
      return t
  }
}

private func substitute(_ j: Int, _ s: Term, _ t: Term, _ c: Int) -> Term {
  switch t {
    case let .variable(_, index) where index == j+c:
      return shift(c, 0, s)
    case let .variable(name, index):
      return .variable(name: name, index: index)
    case let .abstraction(name, type, body):
      return .abstraction(parameter: name, parameterType: type, body: substitute(j, s, body, c+1))
    case let .application(lhs, rhs):
      return .application(left: substitute(j, s, lhs, c), right: substitute(j, s, rhs, c))
    case let .ifElse(conditional, trueBranch, falseBranch):
      return .ifElse(condition: substitute(j, s, conditional, c),
                     trueBranch: substitute(j, s, trueBranch, c),
                     falseBranch: substitute(j, s, falseBranch, c))
    case let .succ(body):
      return .succ(substitute(j, s, body, c))
    case let .pred(body):
      return .pred(substitute(j, s, body, c))
    case let .isZero(body):
      return .isZero(substitute(j, s, body, c))
    default:
      return t
  }
}

private func termSubstop(_ s: Term, _ t: Term) -> Term {
  return shift(-1, 0, substitute(0, shift(1, 0, s), t, 0))
}
