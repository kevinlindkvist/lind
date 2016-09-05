//
//  UnicodeScalarView+Helpers.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

extension String.UnicodeScalarView: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = value.unicodeScalars
  }

  public init(extendedGraphemeClusterLiteral value: String) {
    self = value.unicodeScalars
  }

  public init(unicodeScalarLiteral value: String) {
    self = value.unicodeScalars
  }
}

extension String.UnicodeScalarView: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: UnicodeScalar...) {
    self.init()
    self.append(contentsOf: elements)
  }
}

extension String.UnicodeScalarView: Equatable {}

public func == (lhs: String.UnicodeScalarView, rhs: String.UnicodeScalarView) -> Bool {
  return String(lhs) == String(rhs)
}
