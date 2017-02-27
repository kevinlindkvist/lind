import Foundation

public func evaluate(term: Term, namedTerms: [Term]) -> Term {
  switch term {
  case .unit: return .unit
  // Application and Abstraction
  case .abstraction(_,_,_):
    return term

  case let .application(.abstraction(_, _, body), v2) where isValue(term: v2):
    let t2 = termSubstTop(v2, body)
    return evaluate(term: t2, namedTerms: namedTerms)

  case let .application(v1, t2) where isValue(term: v1):
    let t2p = evaluate(term: t2, namedTerms: namedTerms)
    return evaluate(term: .application(left: v1, right: t2p), namedTerms: namedTerms)

  case let .application(t1, t2):
    let t1p = evaluate(term: t1, namedTerms: namedTerms)
    return evaluate(term: .application(left: t1p, right: t2), namedTerms: namedTerms)
  // Numbers
  case .zero: return .zero
    
  case .isZero(.zero):
    return .trueTerm
  case .isZero(.succ(_)):
    return .falseTerm
  case let .isZero(zeroTerm):
    let evaluatedTerm = evaluate(term: zeroTerm, namedTerms: namedTerms)
    return evaluate(term: .isZero(evaluatedTerm), namedTerms: namedTerms)

  case .succ(.zero):
    return .succ(.zero)
  case let .succ(succTerm):
    return .succ(evaluate(term: succTerm, namedTerms: namedTerms))
    
  case .pred(.zero):
    return .zero
  case let .pred(.succ(succTerm)):
    return succTerm
  case let .pred(predTerm):
    let evaluatedTerm = evaluate(term: predTerm, namedTerms: namedTerms)
    return evaluate(term: .pred(evaluatedTerm), namedTerms: namedTerms)
    
  // Booleans
  case .trueTerm: return .trueTerm
  case .falseTerm: return .falseTerm

  case let .ifThenElse(conditional, trueBranch, falseBranch):
    switch evaluate(term: conditional, namedTerms: namedTerms) {
      case .trueTerm:
        return evaluate(term: trueBranch, namedTerms: namedTerms)
      default:
        return evaluate(term: falseBranch, namedTerms: namedTerms)
    }
  // Variables
  case let .variable(_, index):
    if (index < namedTerms.count) {
      return namedTerms[index]
    } else {
      return term
    }
  // Tuples
  case let .tuple(contents):
    var evaluatedTerms: [String:Term] = [:]
    for (key,value) in contents {
      evaluatedTerms[key] = evaluate(term: value, namedTerms: namedTerms)
    }
    return .tuple(evaluatedTerms)
  case let .letTerm(p, argument, body) where isValue(term: argument):
    let matches = match(pattern: p, argument: argument, namedTerms: namedTerms)
    var substitutedTerm = body
    for (index, name) in p.variables.enumerated() {
      substitutedTerm = substitute(index, matches[name]!, substitutedTerm, 0)
    }
    return evaluate(term: substitutedTerm, namedTerms: namedTerms)
  // Let bindings
  case let .letTerm(p, argument, body):
    let argumentValue = evaluate(term: argument, namedTerms: namedTerms)
    return evaluate(term: .letTerm(pattern: p, argument: argumentValue, body: body), namedTerms: namedTerms)
  case let .tag(label, term, type):
    return .tag(label: label, term: evaluate(term: term, namedTerms: namedTerms), ascribedType: type)
  case let .caseTerm(term, cases):
    switch evaluate(term: term, namedTerms: namedTerms) {
    case let .tag(label, t, _):
      // The typechecker makes sure that this case exists.
      let c = cases.filter { $0.value.label == label }.first!
      return substitute(0, t, c.value.term, 0)
    default:
      assertionFailure()
    }
    return term
  // Fix terms
  case let .fix(.abstraction(_, _, body)):
    return substitute(0, term, body)
  case let .fix(fixedTerm) where isValue(term: fixedTerm):
    return .fix(fixedTerm)
  case let .fix(fixedTerm):
    return evaluate(term: .fix(evaluate(term: fixedTerm, namedTerms: namedTerms)),
                    namedTerms: namedTerms)
  // Lists
  case let .cons(head, tail, type) where !isValue(term: head):
    let evaluatedHead = evaluate(term: head, namedTerms: namedTerms)
    return evaluate(term: .cons(head: evaluatedHead, tail: tail, type: type),
                    namedTerms: namedTerms)
  case let .cons(head, tail, type) where !isValue(term: tail):
    let evaluatedTail = evaluate(term: tail, namedTerms: namedTerms)
    return evaluate(term: .cons(head: head, tail: evaluatedTail, type: type),
                    namedTerms: namedTerms)
  case .cons:
    return term
  case .isNil(.nilList, _):
    return .trueTerm
  case let .isNil(.cons(head, tail, _), _) where isValue(term: head) && isValue(term: tail):
    return .falseTerm
  case let .isNil(list, type) where !isValue(term: list):
    let evaluatedList = evaluate(term: list, namedTerms: namedTerms)
    return evaluate(term: .isNil(list: evaluatedList, type: type), namedTerms: namedTerms)
  case .isNil:
    assertionFailure()
    return .unit
  case let .head(.cons(head, tail, _), _) where isValue(term: head) && isValue(term: tail):
    return head
  case let .head(list, type):
    let evaluatedList = evaluate(term: list, namedTerms: namedTerms)
    return evaluate(term: .head(list: evaluatedList, type: type), namedTerms: namedTerms)
  case let .tail(.cons(head, tail, _), _) where isValue(term: head) && isValue(term: tail):
    return tail
  case let .tail(list, type):
    let evaluatedList = evaluate(term: list, namedTerms: namedTerms)
    return evaluate(term: .tail(list: evaluatedList, type: type), namedTerms: namedTerms)
  case .nilList:
    return term
  }
}

private func match(pattern: Pattern, argument: Term, namedTerms: [Term]) -> [String:Term] {
  switch pattern {
  case let .variable(name):
    return [name: argument]
  case let .record(contents):
    switch argument {
    case let .tuple(arguments):
      var matches: [String:Term] = [:]
      contents.forEach { key, value in
        match(pattern: value, argument: arguments[key]!, namedTerms: namedTerms).forEach { key, value in
          matches[key] = value
        }
      }
      return matches
    default:
      assertionFailure()
      return [:]
    }
  }
}

private func isValue(term: Term) -> Bool {
  switch term {
  case .abstraction: return true
  case .unit: return true
  case .trueTerm: return true
  case .falseTerm: return true
  case let .tuple(contents):
    for (_, value) in contents {
      if !isValue(term: value) {
        return false
      }
    }
    return true
  case let .cons(head, tail, _):
    return isValue(term: head) && isValue(term: tail)
  case .nilList:
    return true
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

func shift(_ d: Int, _ c: Int, _ t: Term) -> Term {
  switch t {
    case let .variable(name, index) where index < c:
      return .variable(name: name, index: index)
    case let .variable(name, index):
      return .variable(name: name, index: index+d)
    case let .abstraction(name, type, body):
      return .abstraction(parameter: name, parameterType: type, body: shift(d, c+1, body))
    case let .application(lhs, rhs):
      return .application(left: shift(d, c, lhs), right: shift(d, c, rhs))
    case let .ifThenElse(conditional, trueBranch, falseBranch):
      return .ifThenElse(condition: shift(d, c, conditional),
                     trueBranch: shift(d, c, trueBranch),
                     falseBranch: shift(d, c, falseBranch))
    case let .succ(body):
      return .succ(shift(d, c, body))
    case let .pred(body):
      return .pred(shift(d, c, body))
    case let .isZero(body):
      return .isZero(shift(d, c, body))
    case let .letTerm(pattern, argument, body):
      return .letTerm(pattern: pattern, argument: shift(d, c+pattern.length, argument), body: shift(d, c+pattern.length, body))
    case let .tuple(contents):
      var newContents: [String:Term] = [:]
      contents.forEach { key, value in
        newContents[key] = shift(d, c, value)
      }
      return .tuple(newContents)
    case let .fix(contents):
      return .fix(shift(d, c, contents))
    case let .cons(head, tail, type):
      return .cons(head: shift(d, c, head), tail: shift(d, c, tail), type: type)
    case let .head(list, type):
      return .head(list: shift(d, c, list), type: type)
    case let .tail(list, type):
      return .tail(list: shift(d, c, list), type: type)
    case let .isNil(list, type):
      return .isNil(list: shift(d, c, list), type: type)
    default:
      return t
  }
}

func substitute(_ j: Int, _ s: Term, _ t: Term, _ c: Int = 0) -> Term {
  switch t {
    case let .variable(_, index) where index == j+c:
      return shift(c, 0, s)
    case let .variable(name, index):
      return .variable(name: name, index: index)
    case let .abstraction(name, type, body):
      return .abstraction(parameter: name, parameterType: type, body: substitute(j, s, body, c+1))
    case let .application(lhs, rhs):
      return .application(left: substitute(j, s, lhs, c), right: substitute(j, s, rhs, c))
    case let .ifThenElse(conditional, trueBranch, falseBranch):
      return .ifThenElse(condition: substitute(j, s, conditional, c),
                     trueBranch: substitute(j, s, trueBranch, c),
                     falseBranch: substitute(j, s, falseBranch, c))
    case let .succ(body):
      return .succ(substitute(j, s, body, c))
    case let .pred(body):
      return .pred(substitute(j, s, body, c))
    case let .isZero(body):
      return .isZero(substitute(j, s, body, c))
    case let .tuple(contents):
      var newContents: [String:Term] = [:]
      contents.forEach { key, value in
        newContents[key] = substitute(j, s, value, c)
      }
      return .tuple(newContents)
    case let .letTerm(pattern, argument, body):
      return .letTerm(pattern: pattern, argument: substitute(j, s, argument, c), body: substitute(j, s, body, c+pattern.length))
    case let .fix(body):
      return .fix(substitute(j, s, body, c))
    case let .cons(head, tail, type):
      return .cons(head: substitute(j, s, head, c), tail: substitute(j, s, tail, c), type: type)
    case let .head(list, type):
      return .head(list: substitute(j, s, list, c), type: type)
    case let .tail(list, type):
      return .tail(list: substitute(j, s, list, c), type: type)
    case let .isNil(list, type):
      return .isNil(list: substitute(j, s, list, c), type: type)
    default:
      return t
  }
}

/// Shifts the term being substituted (`s`) up by one, then substitutes `s` in `t`, 
/// then shifts the result back down.
func termSubstTop(_ s: Term, _ t: Term) -> Term {
  return shift(-1, 0, substitute(0, shift(1, 0, s), t, 0))
}
