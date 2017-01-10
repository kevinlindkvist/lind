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

  func check(program: String, expectation: ULCTerm) {
    switch parseUntypedLambdaCalculus(program) {
      case let .Success(_, term):
        XCTAssertEqual(evaluate(term), expectation)
      default: XCTAssertTrue(false)
    }
  }

  func testEvaluate() {
    let expectation: ULCTerm = .abs("y", .va("y", 0))
    let program = "(\\x.x) \\y.y"
    check(program: program, expectation: expectation)
  }

  func testEvaluateConstant() {
    let expectation: ULCTerm = .va("x", 0)
    let program = "(\\z.x) \\z.z"
    check(program: program, expectation: expectation)
  }

  func testEvaluateIdentifier() {
    let expectation: ULCTerm = .abs("y", .va("y", 0))
    let program = "(\\z.z \\y.y) \\x.x"
    check(program: program, expectation: expectation)
  }

  func testEvaluateRec() {
    let expectation: ULCTerm = .abs("x", .va("y", 1))
    let program = "(\\x.x) (\\x.x) (\\x.y)"
    check(program: program, expectation: expectation)
  }

  func testEvaluateInternal() {
    let expectation: ULCTerm = .abs("j", .va("j", 0))
    let program = "(\\x.\\y.\\z.z y x) (\\i.i) (\\j.j) (\\k.\\l.k)"
    check(program: program, expectation: expectation)
  }

}
