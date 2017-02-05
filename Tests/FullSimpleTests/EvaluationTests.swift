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
      case let .right(term):
        XCTAssertEqual(evaluate(term: term), expectation)
      case let .left(error): XCTAssertTrue(false, "Could not parse \(program): \(error)")
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

  func testTuple() {
    check(program: "{0, unit,true}", expectation: .Tuple(["1":.Zero,"2":.Unit,"3":.True]))
  }

  func testEmptyTuple() {
    check(program: "{}", expectation: .Tuple([:]))
  }

  func testTupleProjection() {
    check(program: "{true}.1", expectation: .True)
  }

  func testLabeledTuple() {
    check(program: "{0, 7:unit,true}", expectation: .Tuple(["1":.Zero,"7":.Unit,"3":.True]))
  }

  func testTupleNonValue() {
    check(program: "{(\\x:bool.0) true}", expectation: .Tuple(["1":.Zero]))
  }

  func testLabeledTupleProjection() {
    check(program: "{0, 7:unit,true}.7", expectation: .Unit)
    check(program: "{0, 7:unit,true}.1", expectation: .Zero)
  }
}
