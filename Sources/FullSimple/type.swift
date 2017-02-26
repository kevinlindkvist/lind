import Foundation

public indirect enum Type {
  case function(parameterType: Type, returnType: Type)
  case boolean
  case integer
  case unit
  case base(typeName: String)
  case product([String:Type])
  case sum([String:Type])
}

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
    case (.unit, .unit):
      return true
    case let (.base(firstType), .base(secondType)):
      return firstType == secondType
    case let (.product(firstContents), .product(secondContents)):
      return firstContents == secondContents
    case let (.sum(firstContents), .sum(secondContents)):
      return firstContents == secondContents
    default:
      return false
  }
}

extension Type: CustomStringConvertible {
  public var description: String {
    switch self {
      case .boolean:
        return "bool"
      case .integer:
        return "int"
      case let .function(parameterType, returnType):
        return "\(parameterType) => \(returnType)"
      case .unit:
        return "unit"
      case let .base(typeName):
        return typeName
      case let .product(productTypes):
        return "{\(productTypes.map { key, value in "\(key):\(value)" }.joined(separator: ","))}"
      case let .sum(sumTypes):
        return "<\(sumTypes.map { key, value in "\(key):\(value)" }.joined(separator: ","))>"
    }
  }
}
