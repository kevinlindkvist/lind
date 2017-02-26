import Foundation

public indirect enum Term {
  case unit
  case abstraction(parameter: String, parameterType: Type, body: Term)
  case application(left: Term, right: Term)
  case trueTerm
  case falseTerm
  case ifThenElse(condition: Term, trueBranch: Term, falseBranch: Term)
  case zero
  case isZero(Term)
  case succ(Term)
  case pred(Term)
  case variable(name: String, index: Int)
  case tuple([String:Term])
  case letTerm(pattern: Pattern, argument: Term, body: Term)
  case tag(label: String, term: Term, ascribedType: Type)
  case caseTerm(term: Term, cases: [String:Case])
  case fix(Term)
}

extension Term: CustomStringConvertible {
  public var description: String {
    switch self {
      case .trueTerm:
        return "true"
      case .falseTerm:
        return "false"
      case let .ifThenElse(t1, t2, t3):
        return "if (\(t1))\n\tthen (\(t2))\n\telse (\(t3))"
      case .zero:
        return "0"
      case let .succ(t):
        return "succ(\(t))"
      case let .pred(t):
        return "pred(\(t))"
      case let .isZero(t):
        return "isZero(\(t))"
      case let .variable(name, index):
        return "\(name)(\(index))"
      case let .abstraction(parameter, type, body):
        return "\\\(parameter):\(type).(\(body))"
      case let .application(lhs, rhs):
        return "\(lhs) \(rhs)"
      case .unit:
        return "unit"
      case let .tuple(values):
        return values.description
      case let .letTerm(pattern, match, body):
        return "\(pattern) = \(match) in \(body)"
      case let .tag(label, term, type):
        return "<\(label)=\(term)> as \(type)"
      case let .caseTerm(term, cases):
        return "case \(term) of\n\t" + cases.map { $0.value.description }.joined(separator: "\n")
      case let .fix(term):
        return "fix \(term)"
    }
  }
}

extension Term: CustomDebugStringConvertible {
  public var debugDescription: String {
    return self.description
  }
}

extension Term: Equatable {
}

public func ==(lhs: Term, rhs: Term) -> Bool {
  switch (lhs, rhs) {
  case (.trueTerm, .trueTerm):
    return true
  case (.falseTerm, .falseTerm):
    return true
  case (.zero, .zero):
    return true
  case let (.succ(t1), .succ(t2)):
    return t1 == t2
  case let (.pred(t1), .pred(t2)):
    return t1 == t2
  case let (.isZero(t1), .isZero(t2)):
    return t1 == t2
  case let (.ifThenElse(t1,t2,t3), .ifThenElse(t11, t22, t33)):
    return t1 == t11 && t2 == t22 && t3 == t33
  case let (.variable(leftName, leftIndex), .variable(rightName, rightIndex)):
    return leftName == rightName && leftIndex == rightIndex
  case let (.abstraction(leftValue), .abstraction(rightValue)):
    return leftValue == rightValue
  case let (.application(leftValue), .application(rightValue)):
    return leftValue == rightValue
  case (.unit, .unit):
    return true
  case let (.tuple(t1), .tuple(t2)):
    return t1 == t2
  case let (.letTerm(p1, a1, b1), .letTerm(p2, a2, b2)):
    return p1 == p2 && a1 == a2 && b1 == b2
  case let (.tag(leftName, leftTerm, leftType), .tag(rightName, rightTerm, rightType)):
    return leftName == rightName && leftTerm == rightTerm && leftType == rightType
  case let (.caseTerm(leftTerm, leftCases), .caseTerm(rightTerm, rightCases)):
    return leftTerm == rightTerm && leftCases == rightCases
  case let (.fix(lhs), .fix(rhs)):
    return lhs == rhs
  default:
    return false
  }
}
