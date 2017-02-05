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
  case Function(parameterType: Type, returnType: Type)
  case Boolean
  case Integer
  case Unit
  case Base(typeName: String)
  case Product([String:Type])
}

public typealias TypeContext = [Int:Type]

extension Type: Equatable {
}

public func ==(lhs: Type, rhs: Type) -> Bool {
  switch (lhs, rhs) {
    case (.Boolean, .Boolean):
      return true
    case (.Integer, .Integer):
      return true
    case let (.Function(t1,t2), .Function(t11, t22)):
      return t1 == t11 && t2 == t22
    case (.Unit, .Unit):
      return true
    case let (.Base(firstType), .Base(secondType)):
      return firstType == secondType
    case let (.Product(firstContents), .Product(secondContents)):
      return firstContents == secondContents
    default:
      return false
  }
}

extension Type: CustomStringConvertible {
  public var description: String {
    switch self {
      case .Boolean:
        return "bool"
      case .Integer:
        return "int"
      case let .Function(parameterType, returnType):
        return "\(parameterType) => \(returnType)"
      case .Unit:
        return "unit"
      case let .Base(typeName):
        return typeName
      case let .Product(productTypes):
        return productTypes.description
    }
  }
}
