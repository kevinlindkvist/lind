//
//  UnicodeScalarView+Helpers.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

extension String.UnicodeScalarView: StringLiteralConvertible {
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

extension String.UnicodeScalarView: ArrayLiteralConvertible {
  public init(arrayLiteral elements: UnicodeScalar...) {
    self.init()
    self.appendContentsOf(elements)
  }
}

extension String.UnicodeScalarView: Equatable {}

public func == (lhs: String.UnicodeScalarView, rhs: String.UnicodeScalarView) -> Bool {
  return String(lhs) == String(rhs)
}