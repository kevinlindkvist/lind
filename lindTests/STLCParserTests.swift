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

  fileprivate func check(program: String, expected: STLCTerm) {
    check(program: program, expected: ([:],expected))
  }

  fileprivate func check(program: String, expected: ParseResult) {
    let expectation: Result<ParseResult, ParseError> = Result.success(expected)
    let result = parseSimplyTypedLambdaCalculus(program)
    switch (result, expectation) {
    case let (.success(lhs), .success(rhs)):
      XCTAssertEqual(lhs.0, rhs.0)
      XCTAssertEqual(lhs.1, rhs.1)
      break
    default:
      XCTAssertTrue(false)
    }
  }

  func testAbsBaseType() {
    let expected: STLCTerm = .abs("x", .bool, .va("x", 0))
    check(program: "\\x:bool.x", expected: expected)
  }
  
  func testSucc() {
    let expected: STLCTerm = .succ(.pred(.zero))
    check(program: "succ(pred 0)", expected: expected)
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
                    expected: (["x":0], expected))
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
}
