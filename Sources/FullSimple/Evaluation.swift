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

private func evaluate(term: Term, context: TermContext) -> Term {
  switch term {
  case .Unit: return .Unit
  // Application and Abstraction
  case .Abstraction(_,_,_):
    return term

  case let .Application(.Abstraction(parameter, _, body), v2) where isValue(term: v2):
    if parameter == "_" {
      return evaluate(term: body, context: context)
    }
    let t2 = termSubstop(v2, body)
    return evaluate(term: t2, context: context)

  case let .Application(v1, t2) where isValue(term: v1):
    let t2p = evaluate(term: t2, context: context)
    return evaluate(term: .Application(left: v1, right: t2p), context: context)

  case let .Application(t1, t2):
    let t1p = evaluate(term: t1, context: context)
    return evaluate(term: .Application(left: t1p, right: t2), context: context)
  // Numbers
  case .Zero: return .Zero
    
  case .IsZero(.Zero):
    return .True
  case .IsZero(.Succ(_)):
    return .False
  case let .IsZero(zeroTerm):
    let evaluatedTerm = evaluate(term: zeroTerm, context: context)
    return evaluate(term: .IsZero(evaluatedTerm), context: context)

  case .Succ(.Zero):
    return .Succ(.Zero)
  case let .Succ(succTerm):
    return .Succ(evaluate(term: succTerm, context: context))
    
  case .Pred(.Zero):
    return .Zero
  case let .Pred(.Succ(succTerm)):
    return succTerm
  case let .Pred(predTerm):
    let evaluatedTerm = evaluate(term: predTerm, context: context)
    return evaluate(term: .Pred(evaluatedTerm), context: context)
    
  // Booleans
  case .True: return .True
  case .False: return .False

  case let .If(conditional, trueBranch, falseBranch):
    switch evaluate(term: conditional, context: context) {
      case .True:
        return evaluate(term: trueBranch, context: context)
      default:
        return evaluate(term: falseBranch, context: context)
    }
  // Variables
  case .Variable(_, _):
    return term
  // Tuples
  case let .Tuple(contents):
    var evaluatedTerms: [String:Term] = [:]
    for (key,value) in contents {
      evaluatedTerms[key] = evaluate(term: value, context: context)
    }
    return .Tuple(evaluatedTerms)
  case let .Pattern(pattern, matchTerm, body):
    let argument = evaluate(term: matchTerm, context: context)
    let substitutions = match(pattern: pattern, argument: argument)
    var currentAbstraction = body
    substitutions.forEach { name, substitution in
      currentAbstraction = termSubstop(substitution, currentAbstraction)
    }
    return evaluate(term: currentAbstraction, context: context)
  }
}

private func match(pattern: Pattern, argument: Term) -> [(String, Term)] {
  switch pattern {
  case let .Variable(name):
    return [(name, argument)]
  case let .Record(contents):
    switch argument {
    case let .Tuple(arguments):
      var matches: [(String, Term)] = []
      contents.forEach { key, value in
        matches.append(contentsOf: match(pattern: value, argument: arguments[key]!))
      }
      return matches
    default:
      return []
    }
  }
}

private func isValue(term: Term) -> Bool {
  switch term {
  case .Abstraction: return true
  case .Unit: return true
  case .True: return true
  case .False: return true
  case let .Tuple(contents):
    for (_, value) in contents {
      if !isValue(term: value) {
        return false
      }
    }
    return true
  default: return isNumericValue(term: term)
  }
}

private func isNumericValue(term: Term) -> Bool {
  switch term {
  case let .Succ(t) where isNumericValue(term: t):
    return true
  case .Zero:
    return true
  default:
    return false
  }
}

private func shift(_ d: Int, _ c: Int, _ t: Term) -> Term {
  switch t {
    case let .Variable(name, index) where index < c:
      return .Variable(name: name, index: index)
    case let .Variable(name, index):
      return .Variable(name: name, index: index+d)
    case let .Abstraction(name, type, body):
      return .Abstraction(parameter: name, parameterType: type, body: shift(d, c+1, body))
    case let .Application(lhs, rhs):
      return .Application(left: shift(d, c, lhs), right: shift(d, c, rhs))
    case let .If(conditional, trueBranch, falseBranch):
      return .If(condition: shift(d, c, conditional),
                     trueBranch: shift(d, c, trueBranch),
                     falseBranch: shift(d, c, falseBranch))
    case let .Succ(body):
      return .Succ(shift(d, c, body))
    case let .Pred(body):
      return .Pred(shift(d, c, body))
    case let .IsZero(body):
      return .IsZero(shift(d, c, body))
    case let .Pattern(pattern, argument, body):
      return .Pattern(pattern: pattern, argument: shift(d, c, argument), body: shift(d, c, body))
    case let .Tuple(contents):
      var newContents: [String:Term] = [:]
      contents.forEach { key, value in
        newContents[key] = shift(d, c, value)
      }
      return .Tuple(newContents)
    default:
      return t
  }
}

private func substitute(_ j: Int, _ s: Term, _ t: Term, _ c: Int) -> Term {
  switch t {
    case let .Variable(_, index) where index == j+c:
      return shift(c, 0, s)
    case let .Variable(name, index):
      return .Variable(name: name, index: index)
    case let .Abstraction(name, type, body):
      return .Abstraction(parameter: name, parameterType: type, body: substitute(j, s, body, c+1))
    case let .Application(lhs, rhs):
      return .Application(left: substitute(j, s, lhs, c), right: substitute(j, s, rhs, c))
    case let .If(conditional, trueBranch, falseBranch):
      return .If(condition: substitute(j, s, conditional, c),
                     trueBranch: substitute(j, s, trueBranch, c),
                     falseBranch: substitute(j, s, falseBranch, c))
    case let .Succ(body):
      return .Succ(substitute(j, s, body, c))
    case let .Pred(body):
      return .Pred(substitute(j, s, body, c))
    case let .IsZero(body):
      return .IsZero(substitute(j, s, body, c))
    case let .Tuple(contents):
      var newContents: [String:Term] = [:]
      contents.forEach { key, value in
        newContents[key] = substitute(j, s, value, c)
      }
      return .Tuple(newContents)
    case let .Pattern(pattern, argument, body):
      return .Pattern(pattern: pattern, argument: substitute(j, s, argument, c), body: substitute(j, s, body, c))
    default:
      return t
  }
}

private func termSubstop(_ s: Term, _ t: Term) -> Term {
  return shift(-1, 0, substitute(0, shift(1, 0, s), t, 0))
}
