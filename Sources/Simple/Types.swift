//
//  LCSimpleTypes.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

public typealias NamingContext = [String:Int]

// MARK: - Types

public indirect enum Type {
  case Function(Type, Type)
  case Bool
  case Integer
  case Unit
  case Base(String)
}

extension Type: Equatable {
}

public func ==(lhs: Type, rhs: Type) -> Bool {
  switch (lhs, rhs) {
    case (.Bool, .Bool): return true
    case (.Integer, .Integer): return true
    case (.Unit, .Unit): return true
    case let (.Base(t1), .Base(t2)): return t1 == t2
    case let (.Function(t1,t2), .Function(t11, t22)): return t1 == t11 && t2 == t22
    default: return false
  }
}

extension Type: CustomStringConvertible {
  public var description: String {
    switch self {
      case .Bool: return "bool"
      case .Integer: return "int"
      case .Unit: return "unit"
      case let .Base(t): return t
      case let .Function(t1, t2): return "\(t1.description)->\(t2.description)"
    }
  }
}

// MARK: - Terms

public indirect enum Term {
  case True
  case False
  case Zero
  case Unit
  case If(Term, Term, Term)
  case Succ(Term)
  case Pred(Term)
  case IsZero(Term)
  case va(String, Int)
  case abs(String, Type, Term)
  case app(Term, Term)
}

extension Term: CustomStringConvertible {
  public var description: String {
    switch self {
      case .True: return "true"
      case .False: return "false"
      case let .If(t1, t2, t3): return "if (\(t1))\n\tthen (\(t2))\n\telse (\(t3))"
      case .Zero: return "0"
      case let .Succ(t): return "succ(\(t))"
      case let .Pred(t): return "pred(\(t))"
      case let .IsZero(t): return "isZero(\(t))"
      case let .va(x, idx): return "\(x):\(idx)"
      case let .abs(x, type, t): return "\\\(x):\(type).(\(t))"
      case let .app(lhs, rhs): return "\(lhs) \(rhs)"
      case .Unit: return "unit"
    }
  }
}

extension Term: Equatable {
}

public func ==(lhs: Term, rhs: Term) -> Bool {
  switch (lhs, rhs) {
    case (.True, .True): return true
    case (.False, .False): return true
    case (.Zero, .Zero): return true
    case (.Unit, .Unit): return true
    case let (.Succ(t1), .Succ(t2)): return t1 == t2
    case let (.Pred(t1), .Pred(t2)): return t1 == t2
    case let (.IsZero(t1), .IsZero(t2)): return t1 == t2
    case let (.If(t1,t2,t3), .If(t11, t22, t33)): return t1 == t11 && t2 == t22 && t3 == t33
    case let (.va(ln, li), .va(rn, ri)): return ln == rn && ri == li
    case let (.abs(lv), .abs(rv)): return lv == rv
    case let (.app(lv), .app(rv)): return lv == rv
    default: return false
  }
}