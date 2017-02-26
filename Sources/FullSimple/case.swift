import Foundation

/// A Case represents an entry in a variant, and contains the label, as well as the associated
/// parameter name, and the body of the case.
public struct Case {
  let label: String
  let parameter: String
  let term: Term
}

extension Case: CustomStringConvertible {
  public var description: String {
    return "<\(label)=\(parameter)> in \(term)"
  }
}

extension Case: Equatable {
}

public func ==(lhs: Case, rhs: Case) -> Bool {
  return lhs.label == rhs.label && lhs.parameter == rhs.parameter && lhs.term == rhs.term
}
