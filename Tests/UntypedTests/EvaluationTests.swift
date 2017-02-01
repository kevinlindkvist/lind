//
//  UntypedLambdaCalculusevaluateTermTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
import Result
import Parser
@testable import Untyped

class UntypedLambdaCalculusEvaluationTests: XCTestCase {

  func check(program: String, expectation: Term) {
    switch parseUntypedLambdaCalculus(program) {
      case let .success(_, term):
        XCTAssertEqual(evaluateTerm(term), expectation)
      default: XCTAssertTrue(false)
    }
  }

  func testevaluateTerm() {
    let expectation: Term = .abs("y", .va("y", 0))
    let program = "(\\x.x) \\y.y"
    check(program: program, expectation: expectation)
  }

  func testevaluateTermConstant() {
    let expectation: Term = .va("x", 0)
    let program = "(\\z.x) \\z.z"
    check(program: program, expectation: expectation)
  }

  func testevaluateTermIdentifier() {
    let expectation: Term = .abs("y", .va("y", 0))
    let program = "(\\z.z \\y.y) \\x.x"
    check(program: program, expectation: expectation)
  }

  func testevaluateTermRec() {
    let expectation: Term = .abs("x", .va("y", 1))
    let program = "(\\x.x) (\\x.x) (\\x.y)"
    check(program: program, expectation: expectation)
  }

  func testevaluateTermInternal() {
    let expectation: Term = .abs("j", .va("j", 0))
    let program = "(\\x.\\y.\\z.z y x) (\\i.i) (\\j.j) (\\k.\\l.k)"
    check(program: program, expectation: expectation)
  }

}
