//
//  UntypedArithmeticParserTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
import lind

class UntypedArithmeticParserTests: XCTestCase {

  func check(program: String, expected: UATerm) {
    switch parseUntypedArithmetic(program) {
    case let .success(result):
      XCTAssertEqual(expected, result.1)
      break
    case .failure(_):
      XCTAssertTrue(false)
      break
    }
  }

  func testTrue() {
    check(program:"true", expected: .tmTrue)
  }

  func testFalse() {
    check(program:"false", expected: .tmFalse)
  }

  func testZero() {
    check(program:"0", expected: .zero)
  }

  func testIfElse() {
    check(program:"if true then 0 else false", expected: .ifElse(IfElseUATerm(conditional: .tmTrue, trueBranch: .zero, falseBranch: .tmFalse)))
  }

  func testNestedIfElse() {
    let innerIf = IfElseUATerm(conditional: .tmTrue, trueBranch: .zero, falseBranch: .tmTrue)
    let outerIf = IfElseUATerm(conditional: .tmFalse, trueBranch: .ifElse(innerIf), falseBranch: .tmFalse)
    check(program:"if false then if true then 0 else true else false", expected: .ifElse(outerIf))
  }

  func testCondIfElse() {
    let outerIf = IfElseUATerm(conditional: .tmFalse, trueBranch: .pred(.zero), falseBranch: .tmFalse)
    check(program:"if false then pred 0 else false", expected: .ifElse(outerIf))
  }

  func testSucc() {
    check(program:"succ 0", expected: .succ(.zero))
  }

  func testPred() {
    check(program:"pred true", expected: .pred(.tmTrue))
  }

  func testIsZero() {
    check(program:"isZero false", expected: .isZero(.tmFalse))
  }

}
