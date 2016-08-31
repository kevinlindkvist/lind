//
//  UntypedLambdaCalculusTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/30/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest

class UntypedLambdaCalculusParserTests: XCTestCase {

  func testParseResult(str: String, _ tms: LCTerm) {
    assertParseResult(str, tms, parseUntypedLambdaCalculus)
  }

  func testVariable() {
    testParseResult("x", .variable(name: "x"))
  }

  func testAbstraction() {
    testParseResult("\\x.x", .abstraction(name: "x", body: .variable(name: "x")))
  }

  func testApplication() {
    testParseResult("\\x.y z", .application(lhs: .abstraction(name: "x", body: .variable(name: "y")),
      rhs: .variable(name: "z")))
  }

  func testApplicationTwice() {
    let lhs: LCTerm = .application(lhs: .abstraction(name: "x", body: .variable(name: "y")), rhs: .variable(name: "z"))
    testParseResult("\\x.y z d", .application(lhs:lhs, rhs: .variable(name: "d")))
  }

  func testApplicationParens() {
    let lhs: LCTerm = .application(lhs: .abstraction(name: "x", body: .variable(name: "x")), rhs: .variable(name: "d"))
    let rhs: LCTerm = .application(lhs: .abstraction(name: "z", body: .variable(name: "z")), rhs: .variable(name: "l"))
    testParseResult("(\\x.x d) (\\z.z l)", .application(lhs: lhs, rhs: rhs))
  }

  func testApplicationAssociativity() {
    let lhs: LCTerm = .application(lhs: .variable(name: "a"), rhs: .variable(name: "b"))
    testParseResult("a b c", .application(lhs: lhs, rhs: .variable(name: "c")))
  }

  func testApplicationAssociativityParens() {
    let rhs: LCTerm = .application(lhs: .variable(name: "b"), rhs: .variable(name: "c"))
    testParseResult("a (b c)", .application(lhs: .variable(name: "a"), rhs: rhs))
  }

}
