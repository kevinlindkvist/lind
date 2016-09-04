//
//  UntypedLambdaCalculusTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/30/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
import Result

private func ==(lhs: [String: Int], rhs: [String: Int] ) -> Bool {
  return NSDictionary(dictionary: lhs).isEqualToDictionary(rhs)
}

class UntypedLambdaCalculusParserTests: XCTestCase {

  private func testParseResult(test: String, expected: ParseResult) {
    let expectation: Result<ParseResult, ParseError> = Result.Success(expected)
    let result = parseUntypedLambdaCalculus(test)
    switch (result, expectation) {
    case let (.Success(lhs), .Success(rhs)):
      XCTAssertEqual(lhs.0, rhs.0)
      XCTAssertEqual(lhs.1, rhs.1)
      break
    default:
      XCTAssertTrue(false)
    }
  }

  func testVariable() {
    let expected: ParseResult = (["x": 0], LCTerm.va("x", 0))
    testParseResult("x", expected: expected)
  }

  func testAbs() {
    let expected: ParseResult = (Dictionary<String, Int>(), .abs("x", .va("x", 0)))
    testParseResult("\\x.x", expected: expected)
  }

  func testAbsAbs() {
    let innerApp: LCTerm = .app(.va("x", 1), .va("y", 0))
    let expected: ParseResult = ([:], .abs("x", .abs("y", .app(innerApp, innerApp))))
    testParseResult("\\x.\\y.(x y) (x y)", expected: expected)
  }

  func testAbsExtension() {
    let expected: ParseResult = ([:], .abs("x", .abs("y", .app(.app(.va("x", 1), .va("y", 0)), .va("x", 1)))))
    testParseResult("\\x.\\y.x y x", expected: expected)
  }

  func testApp() {
    let expected: ParseResult = (["y": 0, "z": 1], (.abs("x", .app(.va("y", 1), .va("z", 2)))))
    testParseResult("\\x.y z", expected: expected)
  }

  func testAppTwice() {
    let body: LCTerm = .app(.app(.va("y", 1), .va("z", 2)), .va("d", 3))
    let expected: LCTerm =  .abs("x", body)
    testParseResult("\\x.y z d", expected: (["y": 0, "z": 1, "d": 2], expected))
  }


  func testAppParens() {
    let lhs: LCTerm = .abs("x", .app(.va("x", 0), .va("d", 1)))
    let rhs: LCTerm = .abs("z", .app(.va("z", 0), .va("l", 2)))
    testParseResult("(\\x.x d) (\\z.z l)", expected: (["d": 0, "l": 1], .app(lhs, rhs)))
  }

  func testDeBruijn() {
    let lhs: LCTerm = .abs("x", .app(.va("x", 0), .va("d", 1)))
    let rhs: LCTerm = .abs("z", .va("z", 0))
    testParseResult("(\\x.(x d)) (\\z.z) l", expected: (["d": 0, "l": 1], .app(.app(lhs, rhs), .va("l", 1))))
  }

  func testSubstitution() {
    let lhs: LCTerm = .abs("y", .app(.va("x", 1), .va("y", 0)))
    let rhs: LCTerm = .app(.va("y", 1), .va("z", 2))
    testParseResult("(\\y.(x y)) (y z)", expected: (["x": 0, "y": 1, "z": 2], .app(lhs, rhs)))
  }

  func testAppAssociativity() {
    let lhs: LCTerm = .app(.va("a", 0), .va("b", 1))
    let expected: LCTerm = .app(lhs, .va("c", 2))
    testParseResult("a b c", expected: (["a": 0, "b": 1, "c": 2], expected))
  }

  func testAppAssociativityParens() {
    let rhs: LCTerm = .app(.va("b", 1), .va("c", 2))
    let expected: LCTerm = .app(.va("a", 0), rhs)
    testParseResult("a (b c)", expected: (["a": 0, "b": 1, "c": 2], expected))
  }

}
