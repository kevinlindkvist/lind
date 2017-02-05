//
//  UntypedLambdaCalculusTerms.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public indirect enum Term {
  case va(String, Int)
  case abs(String, Term)
  case app(Term, Term)
}

extension Term: Equatable {
}

extension Term: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .va(x, idx): return "\(x):\(idx)"
    case let .abs(x, t): return "\\\(x).\(t)"
    case let .app(lhs, rhs): return "(\(lhs) \(rhs))"
    }
  }
}

public func ==(lhs: Term, rhs: Term) -> Bool {
  switch (lhs, rhs) {
    case let (.va(ln, li), .va(rn, ri)): return ln == rn && ri == li
    case let (.abs(lv), .abs(rv)): return lv == rv
    case let (.app(lv), .app(rv)): return lv == rv
    default: return false
  }
}