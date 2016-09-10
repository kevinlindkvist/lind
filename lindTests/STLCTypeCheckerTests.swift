//
//  STLCTypeCheckerTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest

class STLCTypeCheckerTests: XCTestCase {

  func checkProgram(str: String, type: STLCType?) {
    let t = parseSimplyTypedLambdaCalculus(str)
    switch t {
    case let .success(_, t):
      XCTAssertEqual(typeOf(t: t, context: [:]), type)
    default:
      XCTFail()
    }
  }

  func testVar() {
    XCTAssertEqual(typeOf(t: .va("x", 0), context: [0:.nat]), .nat)
  }

  func testAbs() {
    // \x:bool.x : bool -> bool
    XCTAssertEqual(typeOf(t: .abs("x", .bool, .va("x", 0)), context: [:]), .t_t(.bool, .bool))
    // \x:bool.x x : invalid
    XCTAssertEqual(typeOf(t: .abs("x", .bool, .app(.va("x", 0), .va("x", 0))), context: [:]), nil)
  }

  func testIsZero() {
    XCTAssertEqual(typeOf(t: .isZero(.succ(.zero)), context:[:]), .bool)
    XCTAssertEqual(typeOf(t: .isZero(.isZero(.zero)), context:[:]), nil)
  }
  
  func testSucc() {
    XCTAssertEqual(typeOf(t: .pred(.succ(.zero)), context:[:]), .nat)
    XCTAssertEqual(typeOf(t: .pred(.isZero(.zero)), context:[:]), nil)
  }
  
  func tesZero() {
    XCTAssertEqual(typeOf(t: .zero, context:[:]), .nat)
  }

  func testIfElse() {
    let firstConditional = "((\\x:bool.x) true)"
    let thenClause = "((\\y:bool->int.y false) \\z:bool.if (isZero 0) then (succ 0) else pred(succ 0))"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    let incorrectIfElse = "if \(firstConditional) then \(thenClause) else true"
    checkProgram(str: correctIfElse, type: .nat)
    checkProgram(str: incorrectIfElse, type: nil)
  }
  
}
