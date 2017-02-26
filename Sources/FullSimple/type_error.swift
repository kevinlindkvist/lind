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
