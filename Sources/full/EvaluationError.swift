//
//  EvaluationError.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import parser

public enum EvaluationError: Error {
  case parseError(ParseError)
  case typeError(TypeError)
}

extension EvaluationError: Equatable {}

public func == (lhs: EvaluationError, rhs: EvaluationError) -> Bool {
  return true
}

extension EvaluationError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .parseError(error):
        return error.description
      case let .typeError(error):
        return error.description
    }
  }
}

