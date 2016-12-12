//
//  Type.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import Result

public typealias TypeResult = Result<(TypeContext, Type), TypeError>

public indirect enum Type {
  case function(argumentType: Type, returnType: Type)
  case boolean
  case integer
}

public typealias TypeContext = [Int:Type]

extension Type: Equatable {
}

public func ==(lhs: Type, rhs: Type) -> Bool {
  switch (lhs, rhs) {
    case (.boolean, .boolean):
      return true
    case (.integer, .integer):
      return true
    case let (.function(t1,t2), .function(t11, t22)):
      return t1 == t11 && t2 == t22
    default:
      return false
  }
}

extension Type: CustomStringConvertible {
  public var description: String {
    switch self {
      case .boolean: return "bool"
      case .integer: return "int"
      case let .function(argumentType, returnType):
        return "\(argumentType)->\(returnType)"
    }
  }
}
