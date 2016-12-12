//
//  EvaluationError.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public enum EvaluationError: Error {
  case parseError(ParseError)
  case typeError(TypeError)
}

extension EvaluationError: Equatable {}

public func == (lhs: EvaluationError, rhs: EvaluationError) -> Bool {
  return true
}
