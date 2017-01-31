//
//  Result.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public enum ParseError: Error {
  case message(String)
}

extension ParseError: Equatable {}

public func == (lhs: ParseError, rhs: ParseError) -> Bool {
  return true
}

extension ParseError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .message(description):
      return description
    }
  }
}
