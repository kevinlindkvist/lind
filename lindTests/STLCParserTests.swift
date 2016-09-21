//
//  STLCParserTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import XCTest

fileprivate typealias ParseResult = ([String:Int], STLCTerm)

class STLCParserTests: XCTestCase {

  fileprivate func check(program: String, expected: STLCTerm?) {
    if let expected = expected {
      check(program: program, expectedResult: ([:],expected))
    } else {
      check(program: program, expectedResult: nil)
    }
  }

  fileprivate func check(program: String, expectedResult: ParseResult?) {
    let result = parseSimplyTypedLambdaCalculus(program)
    switch (result, expectedResult) {
      case let (.success(lhs), .some(expected)):
        XCTAssertEqual(lhs.0, expected.0)
        XCTAssertEqual(lhs.1, expected.1, "\nExpected \(expected.1)\nParsed:\(lhs.1)")
        break
      case let (.failure(failure), .some(_)): XCTFail("Parsing failed: \(failure)")
      case (.success, .none): XCTFail("Parsing success when expecting failure")
      default: return
    }
  }

  func testAbsBaseType() {
    let expected: STLCTerm = .abs("x", .bool, .va("x", 0))
    check(program: "\\x:bool.x", expected: expected)
  }

  func testAppSpaces() {
    let expected: STLCTerm = .app(.va("a", 0), .va("b", 1))
    check(program: "a b", expectedResult: (["a":0, "b":1],expected))
    check(program: "a  b", expectedResult: (["a":0, "b":1],expected))
    check(program: "a     b", expectedResult: (["a":0, "b":1],expected))
    check(program: "ab", expectedResult: (["ab":0], .va("ab", 0)))
  }
  
  func testSucc() {
    let expected: STLCTerm = .succ(.pred(.zero))
    check(program: "succ(pred 0)", expected: expected)
    check(program: "succ pred 0", expected: expected)
  }
  
  func testPred() {
    let expected: STLCTerm = .pred(.succ(.zero))
    check(program: "pred(succ 0)", expected: expected)
  }

  func testAbsArrowType() {
    let expected: STLCTerm = .abs("x", .t_t(.nat,.bool), .va("x", 0))
    check(program: "\\x:int->bool.x", expected: expected)
  }

  func testIfElseNoParens() {
    let expected: STLCTerm = .ifElse(.succ(.pred(.zero)), .tmFalse, .tmTrue)
    check(program: "if succ pred 0 then false else true", expected: expected)
  }
  
  func testIfElse() {
    let expected: STLCTerm = .ifElse(.abs("x", .bool, .app(.va("x", 0), .va("x", 0))), .tmFalse, .tmTrue)
    check(program: "if \\x:bool.x x then false else true", expected: expected)
  }

  func testIfElseNested() {
    let inner: STLCTerm = .ifElse(.abs("x", .bool, .va("x", 0)), .tmFalse, .tmTrue)
    let expected: STLCTerm = .ifElse(.abs("x", .nat, .app(.va("x", 0), inner)), .abs("y", .t_t(.bool, .nat), .app(.va("y", 0), .va("x", 1))), .tmTrue)
    check(program: "if \\x:int.x if \\x:bool.x then false else true then \\y:bool->int.y x else true",
                    expectedResult: (["x":0], expected))
  }

  func testAppInSucc() {
    let expected: STLCTerm = .succ(.succ(.abs("x", .t_t(.bool, .nat), .app(.va("x", 0), .zero))))
    check(program: "(succ (succ (\\x:bool->int.x 0)))", expected: expected)
  }

  func testIfIsZero() {
    let expected: STLCTerm = .ifElse(.isZero(.zero), .tmFalse, .tmTrue)
    check(program: "if (isZero 0) then false else true", expected: expected)
  }

  func testAppTermInIfClause() {
    let expected: STLCTerm = .ifElse(.tmTrue, .app(.abs("x", .bool, .va("x", 0)), .tmTrue), .succ(.zero))
    check(program: "if true then (\\x:bool.x) true else succ 0", expected: expected)
  }

  func testNestedAbs() {
    let inner: STLCTerm = .abs("y", .t_t(.bool, .unit), .app(.va("y", 0), .va("x", 1)))
    let expected: STLCTerm = .app(.app(.abs("x", .bool, inner), .tmTrue), .abs("z", .bool, .unit))
    check(program: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", expected: expected)
  }

  // MARK - Extension Tests

  func testSequenceUnit() {
    let t1: STLCTerm = .unit
    let t2: STLCTerm = .unit
    check(program:"unit;unit", expected: .app(.abs("_", .unit, t2), t1))
  }

  func testSequenceApp() {
    let t1: STLCTerm = .app(.va("a", 0), .va("b", 1))
    let t2: STLCTerm = .app(.va("c", 2), .va("d", 3))
    let expected: STLCTerm = .app(.abs("_", .unit, t2), t1)
    check(program: "a b; c d", expectedResult: (["a":0, "b":1, "c":2, "d":3],expected))
    check(program: "a b ;c d", expectedResult: (["a":0, "b":1, "c":2, "d":3],expected))
    check(program: "a b; c d", expectedResult: (["a":0, "b":1, "c":2, "d":3],expected))
    check(program: "a b ; c d", expectedResult: (["a":0, "b":1, "c":2, "d":3],expected))
  }

  func testBaseType() {
    let expected: STLCTerm = .abs("x", .base("A"), .va("x", 0))
    check(program: "\\x:A.x", expected: expected)
  }

  func testAbsAbsSequence() {
    let expected: STLCTerm = .app(.abs("x", .t_t(.bool, .unit),
                                       .app(.va("x", 0),.tmTrue)),
                                  .abs("y", .bool, .unit))
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit ; (\\x:bool->unit.x true) \\y:bool.unit",
          expected: .app(.abs("_", .unit, expected), expected))
  }

  func testAs() {
    check(program: "x as bool", expectedResult: (["x":0], .app(.abs("_", .bool, .va("_", 0)), .va("x", 0))))
  }
}
