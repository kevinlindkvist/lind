import Foundation

public typealias TermContext = [String:Int]
public typealias TypeContext = [Int:Type]

/// ParseContext stores all the information needed to be able to parse, type check, and evaluate
/// terms.
public struct ParseContext {
  /// A map from variable names to their current De Bruijn index. This is mainly used by the parser.
  public let terms: TermContext
  /// A map from current term's De Bruijn indices to their associated types. Used mainly by the type
  /// checker.
  public let types: TypeContext
  /// A map that stores user created type aliases, indexed by their given name.
  public let namedTypes: [String:Type]
  /// An array of user created named terms, where the index in the array represents the terms De 
  /// Bruijn index.
  public let namedTerms: [Term]

  public init(terms: TermContext,
              types: TypeContext,
              namedTypes: [String:Type],
              namedTerms: [Term]) {
    self.terms = terms
    self.types = types
    self.namedTypes = namedTypes
    self.namedTerms = namedTerms
  }

  public init(types: TypeContext) {
    self.terms = [:]
    self.types = types
    self.namedTypes = [:]
    self.namedTerms = []
  }

  public init() {
    self.terms = [:]
    self.types = [:]
    self.namedTypes = [:]
    self.namedTerms = []
  }
}
