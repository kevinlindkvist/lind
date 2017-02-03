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

  fileprivate func check(program: String, expected: Term?) {
    switch parseUntypedLambdaCalculus(program) {
    case let .right(result):
      XCTAssertEqual(expected, evaluateTerm(result))
      break
    case let .left(error):
      XCTAssertTrue(expected == nil, error.description)
      break
    }
  }

  func testevaluateTerm() {
    let expected: Term = .abs("y", .va("y", 0))
    let program = "(\\x.x) \\y.y"
    check(program: program, expected: expected)
  }

  func testevaluateTermConstant() {
    let expected: Term = .va("x", 0)
    let program = "(\\z.x) \\z.z"
    check(program: program, expected: expected)
  }

  func testevaluateTermIdentifier() {
    let expected: Term = .abs("y", .va("y", 0))
    let program = "(\\z.z \\y.y) \\x.x"
    check(program: program, expected: expected)
  }

  func testevaluateTermRec() {
    let expected: Term = .abs("x", .va("y", 1))
    let program = "(\\x.x) (\\x.x) (\\x.y)"
    check(program: program, expected: expected)
  }

  func testevaluateTermInternal() {
    let expected: Term = .abs("j", .va("j", 0))
    let program = "(\\x.\\y.\\z.z y x) (\\i.i) (\\j.j) (\\k.\\l.k)"
    check(program: program, expected: expected)
  }

}
