//
//  TypeCheckerTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 1/19/17.
//  Copyright © 2017 lindkvist. All rights reserved.
//

import XCTest

class TypeCheckerTests: XCTestCase {

  func check(program: String, type: Type, context: TypeContext = [:]) {
    switch parse(input: program, terms: [:]) {
    case let .success(_, t):
      switch typeOf(term: t, context: context) {
      case let .success(parsedType):
        XCTAssertEqual(type, parsedType.1)
      case let .failure(error):
        XCTFail("Type check failed: \(error)")
      }
    default:
      XCTFail("Could not parse program: \(program)")
    }
  }

  func check(malformedProgram: String, context: TypeContext = [:]) {
    switch parse(input: malformedProgram, terms: [:]) {
    case let .success(_, t):
      switch typeOf(term: t, context: [:]) {
      case .success:
        XCTFail("Type check did not fail on malformed program.")
      default:
        break
      }
    case .failure:
      XCTFail("Could not parse program.")
    }
  }

  func testVar() {
    check(malformedProgram: "x")
    check(program: "x", type: .integer, context:[0:.integer])
  }

  func testAbs() {
    check(program: "\\x:bool.x", type: .function(parameterType: .boolean, returnType: .boolean))
    check(program: "(\\x:bool.x) true", type: .boolean)
    check(malformedProgram: "\\x:bool.x x")
    check(malformedProgram: "(\\x:bool.x) 0")
  }

  func testIsZero() {
    check(program: "isZero succ 0", type: .boolean)
    check(malformedProgram: "isZero isZero 0")
  }

  func testSucc() {
    check(program: "pred succ 0", type: .integer)
    check(malformedProgram: "pred isZero 0")
  }

  func testZero() {
    check(program: "0", type: .integer)
  }

  func testIfElse() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    let incorrectIfElse = "if \(firstConditional) then \(thenClause) else true"
    check(program: correctIfElse, type: .integer)
    check(malformedProgram: incorrectIfElse)
  }

  func testNestedAbs() {
    check(program: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", type: .Unit)
  }

  // MARK - Extensions

  func testBaseType() {
    check(program: "\\x:A.x", type: .function(parameterType: .base(typeName: "A"), returnType: .base(typeName: "A")))
    check(malformedProgram: "(\\x:A.x) nil")
  }

  func testSequence() {
    check(program: "unit;0", type: .integer)
    check(malformedProgram: "true;0")
  }

  func testAbsUnit() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit", type: .Unit)
  }

  func testAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit; false", type: .boolean)
  }

  func testAbsAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit;(\\x:bool->unit.x true) \\y:bool.unit", type: .Unit)
  }

  func testAs() {
    check(program: "x as bool", type: .boolean, context: [0: .boolean])
    check(malformedProgram: "x as bool", context: [0: .integer])
  }

  func testAsLambda() {
    check(program: "(\\x:bool.unit) as bool->unit", type: .function(parameterType: .boolean, returnType: .Unit))
  }

  func testLet() {
    check(malformedProgram: "let x=0 in \\y:int.y x")
    check(program: "let x=0 in \\y:int.y", type: .function(parameterType: .integer, returnType: .integer))
  }

  func testLetApp() {
    check(program: "let e=\\z:bool->int.(z true) in e \\y:bool.0", type: .integer)
  }

}
