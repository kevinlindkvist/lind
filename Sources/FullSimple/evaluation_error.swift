import Foundation
import Parswift

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

