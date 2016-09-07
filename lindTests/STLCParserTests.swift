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
}
