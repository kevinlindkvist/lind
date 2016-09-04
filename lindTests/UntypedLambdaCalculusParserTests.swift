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
    let expected: (NamingContext, LCTerm) = (["x": 0], LCTerm.va("x", 0))
    testParseResult("x", expected: expected)
  }

  func testabs() {
    let expected: (NamingContext, LCTerm) = (Dictionary<String, Int>(), .abs("x", .va("x", 0)))
    testParseResult("\\x.x", expected: expected)
  }

  func testabsabs() {
    let expected: (NamingContext, LCTerm) = (Dictionary<String, Int>(), .abs("x", .abs("y", .app(.va("x", 1), .app(.va("y", 0), .va("x", 1))))))
    testParseResult("\\x.\\y.x (y x)", expected: expected)
  }

  func testapp() {
    let expected: (NamingContext, LCTerm) = (["y": 0, "z": 1], .app(.abs("x", .va("y", 1)), .va("z", 1)))
    testParseResult("\\x.y z", expected: expected)
  }

  func testappTwice() {
    let lhs: LCTerm = .app(.abs("x", .va("y", 1)), .va("z", 1))
    let expected: LCTerm =  .app(lhs, .va("d", 2))
    testParseResult("\\x.y z d", expected: (["y": 0, "z": 1, "d": 2], expected))
  }


  func testappParens() {
    let lhs: LCTerm = .app(.abs("x", .va("x", 0)), .va("d", 0))
    let rhs: LCTerm = .app(.abs("z", .va("z", 0)), .va("l", 1))
    testParseResult("(\\x.x d) (\\z.z l)", expected: (["d": 0, "l": 1], .app(lhs, rhs)))
  }

  func testappAssociativity() {
    let lhs: LCTerm = .app(.va("a", 0), .va("b", 1))
    let expected: LCTerm = .app(lhs, .va("c", 2))
    testParseResult("a b c", expected: (["a": 0, "b": 1, "c": 2], expected))
  }

  func testappAssociativityParens() {
    let rhs: LCTerm = .app(.va("b", 1), .va("c", 2))
    let expected: LCTerm = .app(.va("a", 0), rhs)
    testParseResult("a (b c)", expected: (["a": 0, "b": 1, "c": 2], expected))
  }

}
