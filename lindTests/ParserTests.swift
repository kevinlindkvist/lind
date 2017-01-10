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
    let expected: Term = .Abstraction(parameter: "x",
                                     parameterType: .boolean,
                                     body: .Variable(name: "x", index: 0))
    check(input: "\\x:bool.x", expectedTerm: expected)
  }

  func testAppSpaces() {
    let expected: Term = .Application(left: .Variable(name: "a", index: 0), right: .Variable(name: "b", index: 1))
    check(input: "a b", expectedResult: .success(["a": 0, "b": 1], expected))
    check(input: "a  b", expectedResult: .success(["a":0, "b":1], expected))
    check(input: "a     b", expectedResult: .success(["a":0, "b":1], expected))
    check(input: "ab", expectedResult: .success(["ab":0], .Variable(name: "ab", index: 0)))
  }
  
  func testSucc() {
    let expected: Term = .Succ(.Pred(.Zero))
    check(input: "succ(pred 0)", expectedTerm: expected)
    check(input: "succ pred 0", expectedTerm: expected)
  }
  
  func testPred() {
    let expected: Term = .Pred(.Succ(.Zero))
    check(input: "pred(succ 0)", expectedTerm: expected)
  }

  func testAbsArrowType() {
    let expected: Term = .Abstraction(parameter: "x", parameterType: .function(argumentType: .integer, returnType: .boolean), body: .Variable(name: "x", index: 0))
    check(input: "\\x:int->bool.x", expectedTerm: expected)
  }

  func testIfElseNoParens() {
    let expected: Term = .If(condition: .Succ(.Pred(.Zero)), trueBranch: .False, falseBranch: .True)
    check(input: "if succ pred 0 then false else true", expectedTerm: expected)
  }
  
  func testIfElse() {
    let condition: Term = .Application(left:
      .Abstraction(parameter: "x", parameterType: .boolean, body: .Variable(name: "x", index: 0)),
                                       right: .Variable(name: "x", index: 0))
    let expected: Term = .If(condition: condition, trueBranch: .False, falseBranch: .True)
    check(input: "if \\x:bool.x x then false else true", expectedTerm: expected)
  }

  func testIfElseNested() {
    let inner: Term = .If(condition:
      .Abstraction(parameter: "x", parameterType: .boolean, body: .Variable(name: "x", index: 0)),
                              trueBranch: .False,
                              falseBranch: .True)
    let expected: Term = .If(condition: .Abstraction(parameter: "x",
                                                         parameterType: .integer,
                                                         body: .Application(left: .Variable(name: "x", index: 0), right: inner)),
                                 trueBranch: .Abstraction(parameter: "y",
                                                          parameterType: .function(argumentType: .boolean, returnType: .integer),
                                                          body: .Application(left: .Variable(name: "y", index: 0),
                                                                             right: .Variable(name: "x", index: 1))),
                                 falseBranch: .True)
    check(input: "if \\x:int.x if \\x:bool.x then false else true then \\y:bool->int.y x else true",
          expectedResult: .success(["x":0], expected))
  }

  func testAppInSucc() {
    let expected: Term = .Succ(.Succ(.Abstraction(parameter: "x",
                                                  parameterType: .function(argumentType: .boolean, returnType: .integer),
                                                  body: .Application(left: .Variable(name: "x", index: 0),
                                                                     right: .Zero))))
    check(input: "(succ (succ (\\x:bool->int.x 0)))", expectedTerm: expected)
  }

  func testIfIsZero() {
    let expected: Term = .If(condition: .IsZero(.Zero), trueBranch: .False, falseBranch: .True)
    check(input: "if (isZero 0) then false else true", expectedTerm: expected)
  }

  func testAppTermInIfClause() {
    let expected: Term = .If(condition: .True,
                                 trueBranch: .Application(left: .Abstraction(parameter: "x",
                                                                             parameterType: .boolean,
                                                                             body: .Variable(name: "x", index: 0)),
                                                          right: .True),
                                 falseBranch: .Succ(.Zero))
    check(input: "if true then (\\x:bool.x) true else succ 0", expectedTerm: expected)
  }

  func testNestedAbs() {
    let inner: Term = .Abstraction(parameter: "y",
                                   parameterType: .function(argumentType: .boolean, returnType: .Unit),
                                   body: .Application(left: .Variable(name: "y", index: 0),
                                                      right: .Variable(name: "x", index: 1)))
    let expected: Term = .Application(left: .Application(left: .Abstraction(parameter: "x",
                                                                            parameterType: .boolean,
                                                                            body: inner),
                                                         right: .True),
                                      right: .Abstraction(parameter: "z", parameterType: .boolean, body: .Unit))
    check(input: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.Unit", expectedTerm: expected)
  }

  // MARK - Extension Tests

  func testSequenceUnit() {
    let t1: Term = .Unit
    let t2: Term = .Unit
    check(input:"unit;unit", expectedTerm: .Application(left: .Abstraction(parameter: "_",
                                                                           parameterType: .Unit,
                                                                           body: t2),
                                                        right: t1))
  }

  func testSequenceApp() {
    let t1: Term = .Application(left: .Variable(name: "a", index: 0),
                                right: .Variable(name: "b", index: 1))
    let t2: Term = .Application(left: .Variable(name: "c", index: 2),
                                right: .Variable(name: "d", index: 3))
    let expected: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: t2),
                                      right: t1)
    check(input: "a b; c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
    check(input: "a b ;c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
    check(input: "a b; c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
    check(input: "a b ; c d", expectedResult: .success(["a":0, "b":1, "c":2, "d":3],expected))
  }

  func testBaseType() {
    let expected: Term = .Abstraction(parameter: "x",
                                      parameterType: .base(typeName: "A"),
                                      body: .Variable(name: "x", index: 0))
    check(input: "\\x:A.x", expectedTerm: expected)
  }

  func testAbsAbsSequence() {
    let expected: Term = .Application(left: .Abstraction(parameter: "x",
                                                         parameterType: .function(argumentType: .boolean, returnType: .Unit),
                                                         body: .Application(left: .Variable(name: "x", index: 0),
                                                                            right: .True)),
                                      right: .Abstraction(parameter: "y",
                                                          parameterType: .boolean,
                                                          body: .Unit))
    check(input: "(\\x:bool->unit.x true) \\y:bool.Unit ; (\\x:bool->unit.x true) \\y:bool.Unit",
          expectedTerm: .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: expected),
                                     right: expected))
  }

  func testAs() {
    check(input: "x as bool",
          expectedResult: .success(["x":0], .Application(left: .Abstraction(parameter: "_",
                                                                            parameterType: .boolean,
                                                                            body: .Variable(name: "_", index: 0)),
                                                         right: .Variable(name: "x", index: 0))))
  }

  func testAsLambda() {
    let body: Term = .Abstraction(parameter: "x", parameterType: .boolean, body: .Unit)
    let expected: Term = .Application(left: .Abstraction(parameter: "_",
                                                         parameterType: .function(argumentType: .boolean, returnType: .Unit),
                                                         body: .Variable(name: "_", index: 0)),
                                      right: body)
    check(input: "(\\x:bool.Unit) as bool->unit", expectedTerm: expected)
  }

  func testLet() {
    let t1: Term = .Zero
    let t2: Term = .Abstraction(parameter: "y",
                                parameterType: .integer,
                                body: .Application(left: .Variable(name: "y", index: 0),
                                                   right: .Variable(name: "x", index: 1)))
    let expected: Term = .Application(left: .Abstraction(parameter: "x", parameterType: .integer, body: t2),
                                      right: t1)
    check(input: "let x=0 in \\y:int.y x", expectedResult: .success(["x":0], expected))
  }

  func testLetApp() {
    let t1: Term = .Abstraction(parameter: "z",
                                parameterType: .function(argumentType: .boolean, returnType: .integer),
                                body: .Application(left: .Variable(name: "z", index: 0),
                                                   right: .True))
    let t2: Term = .Application(left: .Variable(name: "e", index: 0),
                                right: .Abstraction(parameter: "y", parameterType: .boolean, body: .Zero))
    let expected: Term = .Application(left: .Abstraction(parameter: "e",
                                                         parameterType: .function(argumentType: .function(argumentType: .boolean,
                                                                                                          returnType: .integer),
                                                                                  returnType: .integer),
                                                         body: t2),
                                      right: t1)
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expectedResult: .success(["e":0], expected))
  }
}
