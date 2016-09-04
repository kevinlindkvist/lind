//
//  UntypedLambdaCalculusEvaluateTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
import Result

class UntypedLambdaCalculusEvaluationTests: XCTestCase {

  func evaluateAndAssert(program: String, expectation: LCTerm) {
    switch parseUntypedLambdaCalculus(program) {
      case let .Success(_, term):
        XCTAssertEqual(evaluate(term), expectation)
      default: XCTAssertTrue(false)
    }
  }

  func testEvaluate() {
    let expectation: LCTerm = .abs("y", .va("y", 0))
    let program = "(\\x.x) \\y.y"
    evaluateAndAssert(program, expectation: expectation)
  }

  func testEvaluateConstant() {
    let expectation: LCTerm = .va("x", 0)
    let program = "(\\z.x) \\z.z"
    evaluateAndAssert(program, expectation: expectation)
  }

  func testEvaluateIdentifier() {
    let expectation: LCTerm = .abs("y", .va("y", 0))
    let program = "(\\z.z \\y.y) \\x.x"
    evaluateAndAssert(program, expectation: expectation)
  }

  func testEvaluateRec() {
    let expectation: LCTerm = .abs("x", .va("y", 1))
    let program = "(\\x.x) (\\x.x) (\\x.y)"
    evaluateAndAssert(program, expectation: expectation)
  }

  func testEvaluateInternal() {
    let expectation: LCTerm = .abs("j", .va("j", 0))
    let program = "(\\x.\\y.\\z.z y x) (\\i.i) (\\j.j) (\\k.\\l.k)"
    evaluateAndAssert(program, expectation: expectation)
  }

}