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

  func testParseResult(str: String, ts: [Term], error: Bool = false) {
    switch parseUntypedArithmetic(str) {
    case let .Success(result):
      XCTAssertEqual(ts, result)
      break
    case .Failure(_):
      XCTAssertTrue(error)
      break
    }
  }

  func testTrue() {
    testParseResult("true", ts: [.tmTrue])
  }

  func testFalse() {
    testParseResult("false", ts: [.tmFalse])
  }

  func testZero() {
    testParseResult("0", ts: [.zero])
  }

  func testIfElse() {
    testParseResult("if true then 0 else false", ts: [.ifElse(IfElseTerm(conditional: .tmTrue, trueBranch: .zero, falseBranch: .tmFalse))])
  }

  func testNestedIfElse() {
    let innerIf = IfElseTerm(conditional: .tmTrue, trueBranch: .zero, falseBranch: .tmTrue)
    let outerIf = IfElseTerm(conditional: .tmFalse, trueBranch: .ifElse(innerIf), falseBranch: .tmFalse)
    testParseResult("if false then if true then 0 else true else false", ts: [ .ifElse(outerIf) ])
  }

  func testCondIfElse() {
    let outerIf = IfElseTerm(conditional: .tmFalse, trueBranch: .pred(.zero), falseBranch: .tmFalse)
    testParseResult("if false then pred 0 else false", ts: [ .ifElse(outerIf) ])
  }

  func testSucc() {
    testParseResult("succ 0", ts: [.succ(.zero)])
  }

  func testPred() {
    testParseResult("pred true", ts: [.pred(.tmTrue)])
  }

  func testIsZero() {
    testParseResult("isZero false", ts: [.isZero(.tmFalse)])
  }

}
