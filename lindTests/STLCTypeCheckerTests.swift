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
      print(t)
      XCTAssertEqual(typeOf(t: t, context: context), type)
    default:
      XCTFail("Could not parse program: \(program)")
    }
  }

  func testVar() {
    check(program: "x", type: nil)
    check(program: "x", type: .int, context:[0:.int])
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
    check(program: "pred succ 0", type: .int)
    check(program: "pred isZero 0", type: nil)
  }

  func testZero() {
    check(program: "0", type: .int)
  }

  func testIfElse() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    let incorrectIfElse = "if \(firstConditional) then \(thenClause) else true"
    check(program: correctIfElse, type: .int)
    check(program: incorrectIfElse, type: nil)
  }

  func testNestedAbs() {
    check(program: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.Unit", type: .Unit)
  }

  // MARK - Extensions

  func testBaseType() {
    check(program: "\\x:A.x", type: .t_t(.base("A"), .base("A")))
    check(program: "(\\x:A.x) nil", type: nil)
  }

  func testSequence() {
    check(program: "unit;0", type: .int)
    check(program: "true;0", type: nil)
  }

  func testAbsUnit() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.Unit", type: .Unit)
  }

  func testAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.Unit; false", type: .bool)
  }

  func testAbsAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.Unit;(\\x:bool->unit.x true) \\y:bool.Unit", type: .Unit)
  }

  func testAs() {
    check(program: "x as bool", type: .bool, context: [0: .bool])
    check(program: "x as bool", type: nil, context: [0: .int])
  }

  func testAsLambda() {
    check(program: "(\\x:bool.Unit) as bool->unit", type: .t_t(.bool, .Unit))
  }

  func testLet() {
    check(program: "let x=0 in \\y:int.y x", type: nil)
    check(program: "let x=0 in \\y:int.y", type: .t_t(.int, .int))
  }

  func testLetApp() {
    check(program: "let e=\\z:bool->int.(z true) in e \\y:bool.0", type: .int)
  }
}
