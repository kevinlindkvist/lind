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

  func testParseResult(str: String, _ t: UATerm) {
    assertParseResult(str, t, parseUntypedArithmetic)
  }

  func testTrue() {
    testParseResult("true", .tmTrue)
  }

  func testFalse() {
    testParseResult("false", .tmFalse)
  }

  func testZero() {
    testParseResult("0", .zero)
  }

  func testIfElse() {
    testParseResult("if true then 0 else false", .ifElse(IfElseUATerm(conditional: .tmTrue, trueBranch: .zero, falseBranch: .tmFalse)))
  }

  func testNestedIfElse() {
    let innerIf = IfElseUATerm(conditional: .tmTrue, trueBranch: .zero, falseBranch: .tmTrue)
    let outerIf = IfElseUATerm(conditional: .tmFalse, trueBranch: .ifElse(innerIf), falseBranch: .tmFalse)
    testParseResult("if false then if true then 0 else true else false", .ifElse(outerIf))
  }

  func testCondIfElse() {
    let outerIf = IfElseUATerm(conditional: .tmFalse, trueBranch: .pred(.zero), falseBranch: .tmFalse)
    testParseResult("if false then pred 0 else false", .ifElse(outerIf))
  }

  func testSucc() {
    testParseResult("succ 0", .succ(.zero))
  }

  func testPred() {
    testParseResult("pred true", .pred(.tmTrue))
  }

  func testIsZero() {
    testParseResult("isZero false", .isZero(.tmFalse))
  }

}
