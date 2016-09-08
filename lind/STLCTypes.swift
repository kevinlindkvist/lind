//
//  LCSimpleTypes.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

typealias TypeContext = [Int:STLCType]

public indirect enum STLCType {
  case t_t(STLCType, STLCType)
  case bool
  case nat
}

extension STLCType: Equatable {
}

public func ==(lhs: STLCType, rhs: STLCType) -> Bool {
  switch (lhs, rhs) {
    case (.bool, .bool): return true
    case (.nat, .nat): return true
    case let (.t_t(t1,t2), .t_t(t11, t22)): return t1 == t11 && t2 == t22
    default: return false
  }
}

extension STLCType: CustomStringConvertible {
  public var description: String {
    switch self {
      case .bool: return "bool"
      case .nat: return "int"
      case let .t_t(t1, t2): return "\(t1.description)->\(t2.description)"
    }
  }
}

public indirect enum STLCTerm {
  case tmTrue
  case tmFalse
  case ifElse(STLCTerm, STLCTerm, STLCTerm)
  case zero
  case succ(STLCTerm)
  case pred(STLCTerm)
  case isZero(STLCTerm)
  case va(String, Int)
  case abs(String, STLCType, STLCTerm)
  case app(STLCTerm, STLCTerm)
}

extension STLCTerm: CustomStringConvertible {
  public var description: String {
    switch self {
    case .tmTrue: return "true"
    case .tmFalse: return "false"
    case let .ifElse(t1, t2, t3): return "if (\(t1))\n\tthen (\(t2))\n\telse (\(t3))"
    case .zero: return "0"
    case let .succ(t): return "succ(\(t))"
    case let .pred(t): return "pred(\(t))"
    case let .isZero(t): return "isZero(\(t))"
    case let .va(x, idx): return "\(x):\(idx)"
    case let .abs(x, type, t): return "\\\(x):\(type).\(t)"
    case let .app(lhs, rhs): return "(\(lhs) \(rhs))"
    }
  }
}

extension STLCTerm: Equatable {
}

public func ==(lhs: STLCTerm, rhs: STLCTerm) -> Bool {
  switch (lhs, rhs) {
  case (.tmTrue, .tmTrue): return true
  case (.tmFalse, .tmFalse): return true
  case (.zero, .zero): return true
  case let (.succ(t1), .succ(t2)): return t1 == t2
  case let (.pred(t1), .pred(t2)): return t1 == t2
  case let (.isZero(t1), .isZero(t2)): return t1 == t2
  case let (.ifElse(t1,t2,t3), .ifElse(t11, t22, t33)): return t1 == t11 && t2 == t22 && t3 == t33
  case let (.va(ln, li), .va(rn, ri)): return ln == rn && ri == li
  case let (.abs(lv), .abs(rv)): return lv == rv
  case let (.app(lv), .app(rv)): return lv == rv
  default: return false
  }
}
