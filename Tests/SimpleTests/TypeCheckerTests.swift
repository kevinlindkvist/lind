//
//  TypeCheckerTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
@testable import Simple

class TypeCheckerTests: XCTestCase {

  func check(program: String, type: Type?, context: [Int:Type] = [:]) {
    let t = parse(input: program)
    switch t {
    case let .right(t):
      XCTAssertEqual(typeOf(t: t, context: context), type)
    case let .left(error):
      XCTFail("Could not parse program: \(error)")
    }
  }

  func testVar() {
    check(program: "x", type: nil)
    check(program: "x", type: .Integer, context:[0:.Integer])
  }

  func testAbs() {
    check(program: "\\x:bool.x", type: .Function(.Bool, .Bool))
    check(program: "(\\x:bool.x) true", type: .Bool)
    check(program: "\\x:bool.x x", type: nil)
    check(program: "(\\x:bool.x) 0", type: nil)
  }

  func testIsZero() {
    check(program: "isZero succ 0", type: .Bool)
    check(program: "isZero isZero 0", type: nil)
  }

  func testSucc() {
    check(program: "pred succ 0", type: .Integer)
    check(program: "pred isZero 0", type: nil)
  }

  func testZero() {
    check(program: "0", type: .Integer)
  }

  func testIfElse() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    let incorrectIfElse = "if \(firstConditional) then \(thenClause) else true"
    check(program: correctIfElse, type: .Integer)
    check(program: incorrectIfElse, type: nil)
  }

  func testNestedAbs() {
    check(program: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", type: .Unit)
  }

  // MARK - Extensions

  func testBaseType() {
    check(program: "\\x:A.x", type: .Function(.Base("A"), .Base("A")))
    check(program: "(\\x:A.x) nil", type: nil)
  }

  func testSequence() {
    check(program: "unit;0", type: .Integer)
    check(program: "true;0", type: nil)
  }

  func testAbsUnit() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit", type: .Unit)
  }

  func testAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit; false", type: .Bool)
  }

  func testAbsAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit;(\\x:bool->unit.x true) \\y:bool.unit", type: .Unit)
  }

  func testAs() {
    check(program: "x as bool", type: .Bool, context: [0: .Bool])
    check(program: "x as bool", type: nil, context: [0: .Integer])
  }

  func testAsLambda() {
    check(program: "(\\x:bool.unit) as bool->unit", type: .Function(.Bool, .Unit))
  }

  func testLet() {
    check(program: "let x=0 in \\y:int.y x", type: nil)
    check(program: "let x=0 in \\y:int.y", type: .Function(.Integer, .Integer))
  }

  func testLetApp() {
    check(program: "let e=\\z:bool->int.(z true) in e \\y:bool.0", type: .Integer)
  }
}
