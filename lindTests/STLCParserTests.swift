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

  fileprivate func testParseResult(_ test: String, expected: ParseResult) {
    let expectation: Result<ParseResult, ParseError> = Result.success(expected)
    let result = parseSimplyTypedLambdaCalculus(test)
    switch (result, expectation) {
    case let (.success(lhs), .success(rhs)):
      XCTAssertEqual(lhs.0, rhs.0)
      XCTAssertEqual(lhs.1, rhs.1)
      break
    default:
      XCTAssertTrue(false)
    }
  }

  func testIfElse() {
    let expected: STLCTerm = .ifElse(.abs("x", .app(.va("x", 0), .va("x", 0))), .tmFalse, .tmTrue)
    testParseResult("if (\\x.x x) then false else true", expected: ([:], expected))
  }

  func testIfElseNested() {
    let inner: STLCTerm = .ifElse(.abs("x", .va("x", 0)), .tmFalse, .tmTrue)
    let expected: STLCTerm = .ifElse(.abs("x", .app(.va("x", 0), inner)), .abs("y", .app(.va("y", 0), .va("x", 1))), .tmTrue)
    testParseResult("if (\\x.x if (\\x.x) then false else true) then (\\y.y x) else true", expected: (["x":0], expected))
  }

  func testAppInSucc() {
    let expected: STLCTerm = .succ(.succ(.abs("x", .app(.va("x", 0), .zero))))
    testParseResult("(succ (succ (\\x.x 0)))", expected: ([:],expected))
  }

  func testIfIsZero() {
    let expected: STLCTerm = .ifElse(.isZero(.zero), .tmFalse, .tmTrue)
    testParseResult("if (isZero 0) then false else true", expected: ([:],expected))
  }
}
