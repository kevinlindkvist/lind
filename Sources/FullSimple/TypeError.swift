//
//  TypeError.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public enum TypeError: Error {
  case message(String)
}

extension TypeError: Equatable {}

public func == (lhs: TypeError, rhs: TypeError) -> Bool {
  return true
}

extension TypeError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .message(description):
      return description
    }
  }
}
