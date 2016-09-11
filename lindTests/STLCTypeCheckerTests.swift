//
//  STLCTypeCheckerTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest

class STLCTypeCheckerTests: XCTestCase {

  func check(program: String, type: STLCType?, context: [Int:STLCType] = [:]) {
    let t = parseSimplyTypedLambdaCalculus(program)
    switch t {
    case let .success(_, t):
      XCTAssertEqual(typeOf(t: t, context: context), type)
    default:
      XCTFail("Could not parse program: \(program)")
    }
  }

  func testVar() {
    check(program: "x", type: nil)
    check(program: "x", type: .nat, context:[0:.nat])
  }

  func testAbs() {
    check(program: "\\x:bool.x", type: .t_t(.bool, .bool))
    check(program: "(\\x:bool.x) true", type: .bool)
    check(program: "\\x:bool.x x", type: nil)
    check(program: "(\\x:bool.x) 0", type: nil)
  }

  func testIsZero() {
    check(program: "isZero succ 0", type: .bool)
    check(program: "isZero isZero 0", type: nil)
  }

  func testSucc() {
    check(program: "pred succ 0", type: .nat)
    check(program: "pred isZero 0", type: nil)
  }

  func testZero() {
    check(program: "0", type: .nat)
  }

  func testIfElse() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    let incorrectIfElse = "if \(firstConditional) then \(thenClause) else true"
    check(program: correctIfElse, type: .nat)
    check(program: incorrectIfElse, type: nil)
  }
  
}
