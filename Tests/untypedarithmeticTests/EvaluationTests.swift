//
//  UntypedArithmeticEvaluationTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
import Result
@testable import UntypedArithmetic

class UntypedArithmeticEvaluationTests: XCTestCase {

  fileprivate func check(program: String, expected: Term?) {
    switch parseUntypedArithmetic(program) {
    case let .right(result):
      XCTAssertEqual(expected, evaluateUntypedArithmetic(result))
      break
    case let .left(error):
      XCTAssertTrue(expected == nil, error.description)
      break
    }
  }

  func testZero() {
    check(program: "0", expected: .Zero)
  }

  func testIsZero() {
    check(program: "isZero 0", expected: .True)
  }

  func testIsZeroPred() {
    check(program: "isZero succ 0", expected: .False)
  }

  func testIsZeroNestedTrue() {
    check(program: "isZero pred succ 0", expected: .True)
  }
  
  func testIsZeroNestedFalse() {
    check(program: "isZero pred succ succ 0", expected: .False)
  }

  func testIfIsZero() {
    check(program: "if isZero 0 then 0 else true", expected: .Zero)
  }

  func testIfIsZeroFalse() {
    check(program: "if isZero succ 0 then 0 else true", expected: .True)
  }
  
  func testIfTrue() {
    check(program: "if true then 0 else true", expected: .Zero)
  }

  func testNestedIf() {
   check(program: "if if true then false else true then 0 else false", expected: .False)
  }

}
