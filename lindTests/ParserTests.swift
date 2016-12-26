//
//  STLCParserTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import XCTest

class ParserTests: XCTestCase {

  fileprivate func check(input: String, expectedTerm: Term) {
    check(input: input, expectedResult: .success([:], expectedTerm))
  }

  fileprivate func check(input: String, expectedResult: ParseResult) {
    let result = parse(input: input, terms: [:])
    // Can't make Result<T, E> equatable for specific T, E, due to bug in Swift's implementation.
    XCTAssertTrue(expectedResult == result)
  }

  func testAbsBaseType() {
    let expected: Term = .abstraction(parameter: "x",
                                     parameterType: .boolean,
                                     body: .variable(name: "x", index: 0))
    check(input: "\\x:bool.x", expectedTerm: expected)
  }

  func testAppSpaces() {
    let expected: Term = .application(left: .variable(name: "a", index: 0), right: .variable(name: "b", index: 1))
    check(input: "a b", expectedResult: .success(["a": 0, "b": 1], expected))
    check(input: "a  b", expectedResult: .success(["a":0, "b":1], expected))
    check(input: "a     b", expectedResult: .success(["a":0, "b":1], expected))
    check(input: "ab", expectedResult: .success(["ab":0], .variable(name: "ab", index: 0)))
  }
  
  func testSucc() {
    let expected: Term = .succ(.pred(.zero))
    check(input: "succ(pred 0)", expectedTerm: expected)
    check(input: "succ pred 0", expectedTerm: expected)
  }
  
  func testPred() {
    let expected: Term = .pred(.succ(.zero))
    check(input: "pred(succ 0)", expectedTerm: expected)
  }

  func testAbsArrowType() {
    let expected: Term = .abstraction(parameter: "x", parameterType: .function(argumentType: .integer, returnType: .boolean), body: .variable(name: "x", index: 0))
    check(input: "\\x:int->bool.x", expectedTerm: expected)
  }

  func testIfElseNoParens() {
    let expected: Term = .ifElse(condition: .succ(.pred(.zero)), trueBranch: .tmFalse, falseBranch: .tmTrue)
    check(input: "if succ pred 0 then false else true", expectedTerm: expected)
  }
  
  func testIfElse() {
    let condition: Term = .application(left:
      .abstraction(parameter: "x", parameterType: .boolean, body: .variable(name: "x", index: 0)),
                                       right: .variable(name: "x", index: 0))
    let expected: Term = .ifElse(condition: condition, trueBranch: .tmFalse, falseBranch: .tmTrue)
    check(input: "if \\x:bool.x x then false else true", expectedTerm: expected)
  }

  func testIfElseNested() {
    let inner: Term = .ifElse(condition:
      .abstraction(parameter: "x", parameterType: .boolean, body: .variable(name: "x", index: 0)),
                              trueBranch: .tmFalse,
                              falseBranch: .tmTrue)
    let expected: Term = .ifElse(condition: .abstraction(parameter: "x",
                                                         parameterType: .integer,
                                                         body: .application(left: .variable(name: "x", index: 0), right: inner)),
                                 trueBranch: .abstraction(parameter: "y",
                                                          parameterType: .function(argumentType: .boolean, returnType: .integer),
                                                          body: .application(left: .variable(name: "y", index: 0),
                                                                             right: .variable(name: "x", index: 1))),
                                 falseBranch: .tmTrue)
    check(input: "if \\x:int.x if \\x:bool.x then false else true then \\y:bool->int.y x else true",
          expectedResult: .success(["x":0], expected))
  }

  func testAppInSucc() {
    let expected: Term = .succ(.succ(.abstraction(parameter: "x",
                                                  parameterType: .function(argumentType: .boolean, returnType: .integer),
                                                  body: .application(left: .variable(name: "x", index: 0),
                                                                     right: .zero))))
    check(input: "(succ (succ (\\x:bool->int.x 0)))", expectedTerm: expected)
  }

  func testIfIsZero() {
    let expected: Term = .ifElse(condition: .isZero(.zero), trueBranch: .tmFalse, falseBranch: .tmTrue)
    check(input: "if (isZero 0) then false else true", expectedTerm: expected)
  }

  func testAppTermInIfClause() {
    let expected: Term = .ifElse(condition: .tmTrue,
                                 trueBranch: .application(left: .abstraction(parameter: "x",
                                                                             parameterType: .boolean,
                                                                             body: .variable(name: "x", index: 0)),
                                                          right: .tmTrue),
                                 falseBranch: .succ(.zero))
    check(input: "if true then (\\x:bool.x) true else succ 0", expectedTerm: expected)
  }

  func testNestedAbs() {
    let inner: Term = .abstraction(parameter: "y",
                                   parameterType: .function(argumentType: .boolean, returnType: .unit),
                                   body: .application(left: .variable(name: "y", index: 0),
                                                      right: .variable(name: "x", index: 1)))
    let expected: Term = .application(left: .application(left: .abstraction(parameter: "x",
                                                                            parameterType: .boolean,
                                                                            body: inner),
                                                         right: .tmTrue),
                                      right: .abstraction(parameter: "z", parameterType: .boolean, body: .unit))
    check(input: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", expectedTerm: expected)
  }

  // MARK - Extension Tests

  func testSequenceUnit() {
    let t1: Term = .unit
    let t2: Term = .unit
    check(input:"unit;unit", expectedTerm: .application(left: .abstraction(parameter: "_",
                                                                           parameterType: .unit,
                                                                           body: t2),
                                                        right: t1))
  }

  func testSequenceApp() {
    let t1: Term = .application(left: .variable(name: "a", index: 0),
                                right: .variable(name: "b", index: 1))
    let t2: Term = .application(left: .variable(name: "c", index: 2),
                                right: .variable(name: "d", index: 3))
    let expected: Term = .application(left: .abstraction(parameter: "_", parameterType: .unit, body: t2),
                                      right: t1)
    check(input: "a b; c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
    check(input: "a b ;c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
    check(input: "a b; c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
    check(input: "a b ; c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
  }

  func testBaseType() {
    let expected: Term = .abstraction(parameter: "x",
                                      parameterType: .base(typeName: "A"),
                                      body: .variable(name: "x", index: 0))
    check(input: "\\x:A.x", expectedTerm: expected)
  }

  func testAbsAbsSequence() {
    let expected: Term = .application(left: .abstraction(parameter: "x",
                                                         parameterType: .function(argumentType: .boolean, returnType: .unit),
                                                         body: .application(left: .variable(name: "x", index: 0),
                                                                            right: .tmTrue)),
                                      right: .abstraction(parameter: "y",
                                                          parameterType: .boolean,
                                                          body: .unit))
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit ; (\\x:bool->unit.x true) \\y:bool.unit",
          expectedTerm: .application(left: .abstraction(parameter: "_", parameterType: .unit, body: expected),
                                     right: expected))
  }

  func testAs() {
    check(input: "x as bool",
          expectedResult: .success(["x":0], .application(left: .abstraction(parameter: "_",
                                                                            parameterType: .boolean,
                                                                            body: .variable(name: "_", index: 0)),
                                                         right: .variable(name: "x", index: 0))))
  }

  func testAsLambda() {
    let body: Term = .abstraction(parameter: "x", parameterType: .boolean, body: .unit)
    let expected: Term = .application(left: .abstraction(parameter: "_",
                                                         parameterType: .function(argumentType: .boolean, returnType: .unit),
                                                         body: .variable(name: "_", index: 0)),
                                      right: body)
    check(input: "(\\x:bool.unit) as bool->unit", expectedTerm: expected)
  }

  func testLet() {
    let t1: Term = .zero
    let t2: Term = .abstraction(parameter: "y",
                                parameterType: .integer,
                                body: .application(left: .variable(name: "y", index: 0),
                                                   right: .variable(name: "x", index: 1)))
    let expected: Term = .application(left: .abstraction(parameter: "x", parameterType: .integer, body: t2),
                                      right: t1)
    check(input: "let x=0 in \\y:int.y x", expectedResult: .success(["x":0], expected))
  }

  func testLetApp() {
    let t1: Term = .abstraction(parameter: "z",
                                parameterType: .function(argumentType: .boolean, returnType: .integer),
                                body: .application(left: .variable(name: "z", index: 0),
                                                   right: .tmTrue))
    let t2: Term = .application(left: .variable(name: "e", index: 0),
                                right: .abstraction(parameter: "y", parameterType: .boolean, body: .zero))
    let expected: Term = .application(left: .abstraction(parameter: "e",
                                                         parameterType: .function(argumentType: .function(argumentType: .boolean,
                                                                                                          returnType: .integer),
                                                                                  returnType: .integer),
                                                         body: t2),
                                      right: t1)
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expectedResult: .success(["e":0], expected))
  }
}
