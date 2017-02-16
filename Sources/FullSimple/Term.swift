//
//  Term.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public indirect enum Pattern {
  case Variable(name: String)
  case Record([String:Pattern])

  var length: Int {
    switch self {
      case .Variable:
        return 1
      case let .Record(contents):
        return contents.map { key, value in value.length }.reduce(0, +)
    }
  }

  var variables: [String] {
    switch self {
    case let .Variable(name):
      return [name]
    case let .Record(contents):
      return contents.flatMap { _, pattern in pattern.variables }
    }
  }
}

extension Pattern: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .Variable(name):
      return name
    case let .Record(contents):
      var string = "{"
      contents.forEach { key, value in
        string += "\(key)=\(value.description),"
      }
      return string + "}"
    }
  }
}

extension Pattern: Equatable {
}

public func ==(lhs: Pattern, rhs: Pattern) -> Bool {
  switch (lhs, rhs) {
  case let (.Variable(name), .Variable(otherName)):
    return name == otherName
  case let (.Record(contents), .Record(otherContents)):
    return contents == otherContents
  default: return false
  }
}

public struct Case {
  let label: String
  let parameter: String
  let term: Term
}

extension Case: CustomStringConvertible {
  public var description: String {
    return "<\(label)=\(parameter)> in \(term)"
  }
}

extension Case: Equatable {
}

public func ==(lhs: Case, rhs: Case) -> Bool {
  return lhs.label == rhs.label && lhs.parameter == rhs.parameter && lhs.term == rhs.term
}

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
  case Let(pattern: Pattern, argument: Term, body: Term)
  case Tag(label: String, term: Term, ascribedType: Type)
  case Case(term: Term, cases: [String:Case])
  case Fix(Term)
}

public typealias TermContext = [String:Int]

public struct ParseContext {
  let terms: TermContext
  let types: TypeContext
  let namedTypes: [String:Type]
  public let namedTerms: [Term]

  public init(terms: TermContext, types: TypeContext, namedTypes: [String:Type], namedTerms: [Term]) {
    self.terms = terms
    self.types = types
    self.namedTypes = namedTypes
    self.namedTerms = namedTerms
  }
}

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
      case let .Variable(name, index):
        return "\(name)(\(index))"
      case let .Abstraction(parameter, type, body):
        return "\\\(parameter):\(type).(\(body))"
      case let .Application(lhs, rhs):
        return "\(lhs) \(rhs)"
      case .Unit:
        return "unit"
      case let .Tuple(values):
        return values.description
      case let .Let(pattern, match, body):
        return "\(pattern) = \(match) in \(body)"
      case let .Tag(label, term, type):
        return "<\(label)=\(term)> as \(type)"
      case let .Case(term, cases):
        return "case \(term) of\n\t" + cases.map { $0.value.description }.joined(separator: "\n")
      case let .Fix(term):
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
  case let (.Tuple(t1), .Tuple(t2)):
    return t1 == t2
  case let (.Let(p1, a1, b1), .Let(p2, a2, b2)):
    return p1 == p2 && a1 == a2 && b1 == b2
  case let (.Tag(leftName, leftTerm, leftType), .Tag(rightName, rightTerm, rightType)):
    return leftName == rightName && leftTerm == rightTerm && leftType == rightType
  case let (.Case(leftTerm, leftCases), .Case(rightTerm, rightCases)):
    return leftTerm == rightTerm && leftCases == rightCases
  case let (.Fix(lhs), .Fix(rhs)):
    return lhs == rhs
  default:
    return false
  }
}
