//
//  UntypedArithmeticParserTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import XCTest
@testable import UntypedArithmetic

class UntypedArithmeticParserTests: XCTestCase {

  func check(program: String, expected: Term) {
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
    check(program:"true", expected: .True)
  }

  func testFalse() {
    check(program:"false", expected: .False)
  }

  func testZero() {
    check(program:"0", expected: .Zero)
  }

  func testIfElse() {
    check(program:"if true then 0 else false", expected: .If(IfElseTerm(conditional: .True, trueBranch: .Zero, falseBranch: .False)))
  }

  func testNestedIfElse() {
    let innerIf = IfElseTerm(conditional: .True, trueBranch: .Zero, falseBranch: .True)
    let outerIf = IfElseTerm(conditional: .False, trueBranch: .If(innerIf), falseBranch: .False)
    check(program:"if false then if true then 0 else true else false", expected: .If(outerIf))
  }

  func testCondIfElse() {
    let outerIf = IfElseTerm(conditional: .False, trueBranch: .Pred(.Zero), falseBranch: .False)
    check(program:"if false then pred 0 else false", expected: .If(outerIf))
  }

  func testSucc() {
    check(program:"succ 0", expected: .Succ(.Zero))
  }

  func testPred() {
    check(program:"pred true", expected: .Pred(.True))
  }

  func testIsZero() {
    check(program:"isZero false", expected: .IsZero(.False))
  }

}
