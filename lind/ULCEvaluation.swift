//
//  UntypedLambdaCalculusEvaluation.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/31/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

private typealias NameLookup = [Int:ULCTerm]

func evaluate(term: ULCTerm) -> ULCTerm {
  switch evaluate(term, [:]) {
    case let .Some(t): return evaluate(t)
    case .None: return term
  }
}

private func evaluate(term: ULCTerm, _ context: NameLookup) -> ULCTerm? {
  switch term {
  case let .app(.abs(_,body), v2) where isValue(v2, context):
    return termSubstop(v2, body)
  case let .app(v1, t2) where isValue(v1, context):
    if let t2p = evaluate(t2, context) {
      return .app(v1, t2p)
    }
    return nil
  case let .app(t1, t2):
    if let t1p = evaluate(t1, context) {
      return .app(t1p, t2)
    }
    return nil
  default: return nil
  }
}

private func isValue(term: ULCTerm, _ context: NameLookup) -> Bool {
  switch term {
    case .abs: return true
    default: return false
  }
}

private func shift(d: Int, _ c: Int, _ t: ULCTerm) -> ULCTerm {
  switch t {
    case let .va(name, index) where index < c: return .va(name, index)
    case let .va(name, index): return .va(name, index+d)
    case let .abs(name, body): return .abs(name, shift(d, c+1, body))
    case let .app(lhs, rhs): return .app(shift(d, c, lhs), shift(d, c, rhs))
  }
}

private func substitute(j: Int, _ s: ULCTerm, _ t: ULCTerm, _ c: Int) -> ULCTerm {
  switch t {
  case let .va(_, index) where index == j+c: return shift(c, 0, s)
  case let .va(name, index): return .va(name, index)
  case let .abs(name, body): return .abs(name, substitute(j, s, body, c+1))
  case let .app(lhs, rhs): return .app(substitute(j, s, lhs, c), substitute(j, s, rhs, c))
  }
}

private func termSubstop(s: ULCTerm, _ t: ULCTerm) -> ULCTerm {
  return shift(-1, 0, substitute(0, shift(1, 0, s), t, 0))
}