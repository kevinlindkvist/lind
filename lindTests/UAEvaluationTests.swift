//
//  UntypedArithmeticEvaluationTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
import Result

class UntypedArithmeticEvaluationTests: XCTestCase {

  fileprivate func check(program: String, expected: UATerm?) {
    switch parseUntypedArithmetic(program) {
    case let .success(result):
      XCTAssertEqual(expected, evaluateUntypedArithmetic(result.1))
      break
    case .failure(_):
      XCTAssertTrue(expected == nil)
      break
    }
  }

  func testZero() {
    check(program: "0", expected: .zero)
  }

  func testIsZero() {
    check(program: "isZero 0", expected: .tmTrue)
  }

  func testIsZeroPred() {
    check(program: "isZero succ 0", expected: .tmFalse)
  }

  func testIsZeroNestedTrue() {
    check(program: "isZero pred succ 0", expected: .tmTrue)
  }
  
  func testIsZeroNestedFalse() {
    check(program: "isZero pred succ succ 0", expected: .tmFalse)
  }

  func testIfIsZero() {
    check(program: "if isZero 0 then 0 else true", expected: .zero)
  }

  func testIfIsZeroFalse() {
    check(program: "if isZero succ 0 then 0 else true", expected: .tmTrue)
  }
  
  func testIfTrue() {
    check(program: "if true then 0 else true", expected: .zero)
  }

  func testNestedIf() {
   check(program: "if if true then false else true then 0 else false", expected: .tmFalse)
  }

}
