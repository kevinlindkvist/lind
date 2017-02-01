//
//  EvaluationTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 1/18/17.
//  Copyright © 2017 lindkvist. All rights reserved.
//

import XCTest
@testable import FullSimple

class EvaluationTests: XCTestCase {

  func check(program: String, expectation: Term) {
    switch parse(input: program, terms: [:]) {
      case let .success(_, term):
        XCTAssertEqual(evaluate(term: term), expectation)
      default: XCTAssertTrue(false)
    }
  }

  func testEvaluate() {
    let expectation: Term = .Abstraction(parameter: "y",
                                         parameterType: .Unit,
                                         body: .Variable(name: "y", index: 0))
    let program = "(\\x:unit.x) \\y:unit.y"
    check(program: program, expectation: expectation)
  }

  func testEvaluateConstant() {
    let expectation: Term = .Variable(name: "x", index: 0)
    let program = "(\\z:unit->unit.x) \\z:unit.z"
    check(program: program, expectation: expectation)
  }

  func testEvaluateConstantBaseType() {
    let expectation: Term = .Variable(name: "x", index: 0)
    let program = "(\\z:A->A.x) \\z:A.z"
    check(program: program, expectation: expectation)
  }

  func testEvaluateIdentifier() {
    let expectation: Term = .Abstraction(parameter: "y",
                                         parameterType: .Unit,
                                         body: .Variable(name: "y", index: 0))
    let program = "(\\z:unit->unit->unit.z \\y:unit.y) \\x:unit->unit.x"
    check(program: program, expectation: expectation)
  }

  func testEvaluateWildCard() {
    let expectation: Term = .Unit
    let program = "(\\_:bool.unit) true"
    check(program: program, expectation: expectation)
  }
  
  func testAscription() {
    check(program: "0 as int", expectation: .Zero)
  }
}
