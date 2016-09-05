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

  fileprivate func evaluateString(_ str: String, ts: UATerm, fails: Bool = false) {
    switch parseUntypedArithmetic(str) {
    case let .success(result):
      XCTAssertEqual(ts, evaluateUntypedArithmetic(result.1))
      break
    case .failure(_):
      XCTAssertTrue(fails)
      break
    }
  }

  func testFile() {
    let lines = [
      "0; 0",
      "isZero 0; true",
      "isZero succ 0; false",
      "isZero pred succ 0; true",
      "isZero pred succ succ 0; false",
      "if isZero 0 then false else true; false",
      "if isZero succ 0 then false else true; true",
      "if true then 0 else false; 0",
      "if if true then false else true then 0 else false; false",
      ]
    parseAndEvaluateLines(lines, parser: parseUntypedArithmetic, evaluator: evaluateUntypedArithmetic)
  }

}
