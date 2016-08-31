//
//  UntypedLambdaCalculusTerms.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public indirect enum LCTerm {
  case variable(name: String)
  case abstraction(name: String, body: LCTerm)
  case application(lhs: LCTerm, rhs: LCTerm)
}

extension LCTerm: Equatable {
}

extension LCTerm: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .variable(name: x): return "\(x)"
    case let .abstraction(name: x, body:t): return "\\\(x).\(t)"
    case let .application(lhs: lhs, rhs:rhs): return "\(lhs) \(rhs)"
    }
  }
}

public func ==(lhs: LCTerm, rhs: LCTerm) -> Bool {
  switch (lhs, rhs) {
  case let (.variable(lv), .variable(rv)): return lv == rv
  case let (.abstraction(lv), .abstraction(rv)): return lv == rv
  case let (.application(lv), .application(rv)): return lv == rv
  default: return false
  }
}