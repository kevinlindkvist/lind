//
//  STLCTypeCheckerTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest

class STLCTypeCheckerTests: XCTestCase {

  func testVar() {
    XCTAssertEqual(typeOf(t: .va("x", 0), context: [0:.nat]), .nat)
  }

  func testAbs() {
    // \x:bool.x : bool -> bool
    XCTAssertEqual(typeOf(t: .abs("x", .bool, .va("x", 0)), context: [:]), .t_t(.bool, .bool))
    // \x:bool.x x : invalid
    XCTAssertEqual(typeOf(t: .abs("x", .bool, .app(.va("x", 0), .va("x", 0))), context: [:]), nil)
  }

  func testIfElse() {
    let firstConditional = "((\\x:bool.x) true)"
    let thenClause = "((\\y:bool->int.y false) \\z:bool.if (z) then (succ 0) else pred(succ(succ(0))))"
    let ifElse =
      parseSimplyTypedLambdaCalculus("if \(firstConditional) then \(thenClause) else 0")
    switch ifElse {
    case let .success(_, t):
      XCTAssertEqual(typeOf(t: t, context: [:]), .nat)
    default:
      XCTFail()
    }
  }

}
