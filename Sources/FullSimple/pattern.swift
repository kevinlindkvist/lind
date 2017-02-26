import Foundation

/// A pattern represents the left hand side of a let-binding.
public indirect enum Pattern {
  case Variable(name: String)
  case Record([String:Pattern])

  /// Computes the length of the pattern in terms of how many variables it binds.
  ///
  /// - returns: The number of variables the pattern binds.
  var length: Int {
    switch self {
      case .Variable:
        return 1
      case let .Record(contents):
        return contents.map { key, value in value.length }.reduce(0, +)
    }
  }

  /// Returns an array of strings representing the bound labels in the pattern.
  ///
  /// - returns: The labels that the pattern binds.
  var variables: [String] {
    switch self {
    case let .Variable(name):
      return [name]
    case let .Record(contents):
      return contents.flatMap { _, pattern in pattern.variables }
    }
  }
}

/// Extends Pattern to provide human readable descriptions.
extension Pattern: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .Variable(name):
      return name
    case let .Record(contents):
      var string = "{"
      contents.forEach { key, value in
        string += "\(key)=\(value.description),"
      }
      return string + "}"
    }
  }
}

extension Pattern: Equatable {
}

/// Compares two Patterns for equality. Patterns are considered equal if they bind the same labels,
/// and the same structure.
public func ==(lhs: Pattern, rhs: Pattern) -> Bool {
  switch (lhs, rhs) {
  case let (.Variable(name), .Variable(otherName)):
    return name == otherName
  case let (.Record(contents), .Record(otherContents)):
    return contents == otherContents
  default: return false
  }
}
