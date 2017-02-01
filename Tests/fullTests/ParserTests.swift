//
//  ParserTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import XCTest
@testable import FullSimple

class ParserTests: XCTestCase {

  fileprivate func check(input: String, expectedTerm: Term) {
    check(input: input, expectedResult: .success([:], expectedTerm))
  }

  fileprivate func check(input: String, expectedResult: ParseResult) {
    let result = parse(input: input, terms: [:])
    switch (result, expectedResult) {
    case let (.success(t1), .success(t2)):
      XCTAssertEqual(t1.0, t2.0)
      XCTAssertEqual(t1.1, t2.1)
    case (.failure, .failure):
      break
    default:
      XCTFail()
    }
  }

  func testAbsBaseType() {
    let expected: Term = .Abstraction(parameter: "x",
                                      parameterType: .Boolean,
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
    let expected: Term = .Abstraction(parameter: "x", parameterType: .Function(parameterType: .Integer, returnType: .Boolean), body: .Variable(name: "x", index: 0))
    check(input: "\\x:int->bool.x", expectedTerm: expected)
  }

  func testIfElseNoParens() {
    let expected: Term = .If(condition: .Succ(.Pred(.Zero)), trueBranch: .False, falseBranch: .True)
    check(input: "if succ pred 0 then false else true", expectedTerm: expected)
  }

  func testIfElse() {
    let condition: Term = .Application(left:
      .Abstraction(parameter: "x", parameterType: .Boolean, body: .Variable(name: "x", index: 0)),
                                       right: .True)
    let expected: Term = .If(condition: condition, trueBranch: .False, falseBranch: .True)
    check(input: "if (\\x:bool.x) true then false else true", expectedTerm: expected)
  }

  func testIfElseNested() {
    let inner: Term = .If(condition:
      .Abstraction(parameter: "x", parameterType: .Boolean, body: .Variable(name: "x", index: 0)),
                          trueBranch: .False,
                          falseBranch: .True)
    let expected: Term = .If(condition: .Abstraction(parameter: "x",
                                                     parameterType: .Integer,
                                                     body: .Application(left: .Variable(name: "x", index: 0), right: inner)),
                             trueBranch: .Abstraction(parameter: "y",
                                                      parameterType: .Function(parameterType: .Boolean, returnType: .Integer),
                                                      body: .Application(left: .Variable(name: "y", index: 0),
                                                                         right: .Variable(name: "x", index: 1))),
                             falseBranch: .True)
    check(input: "if \\x:int.x if \\x:bool.x then false else true then \\y:bool->int.y x else true",
          expectedResult: .success(["x":0], expected))
  }

  func testAppInSucc() {
    let expected: Term = .Succ(.Succ(.Abstraction(parameter: "x",
                                                  parameterType: .Function(parameterType: .Boolean, returnType: .Integer),
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
                                                                         parameterType: .Boolean,
                                                                         body: .Variable(name: "x", index: 0)),
                                                      right: .True),
                             falseBranch: .Succ(.Zero))
    check(input: "if true then (\\x:bool.x) true else succ 0", expectedTerm: expected)
  }

  func testNestedAbs() {
    let inner: Term = .Abstraction(parameter: "y",
                                   parameterType: .Function(parameterType: .Boolean, returnType: .Unit),
                                   body: .Application(left: .Variable(name: "y", index: 0),
                                                      right: .Variable(name: "x", index: 1)))
    let expected: Term = .Application(left: .Application(left: .Abstraction(parameter: "x",
                                                                            parameterType: .Boolean,
                                                                            body: inner),
                                                         right: .True),
                                      right: .Abstraction(parameter: "z", parameterType: .Boolean, body: .Unit))
    check(input: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", expectedTerm: expected)
  }


  func testNestedFunctionApplication() {
    let body: Term = .Application(left: .Variable(name: "f", index: 1), right: .Application(left: .Variable(name: "f", index: 1), right: .Variable(name: "x", index: 0)))
    let innerTerm: Term = .Abstraction(parameter: "x", parameterType: .Integer, body: body)
    let outerTerm: Term = .Abstraction(parameter: "f", parameterType: .Function(parameterType: .Integer, returnType: .Integer), body: innerTerm)
    check(input: "\\f:int->int.\\x:int.f (f x)", expectedTerm: outerTerm)
  }

  func testLambdaBaseType() {
    check(input: "\\x:A.x",
          expectedTerm: .Abstraction(parameter: "x",
                                     parameterType: .Base(typeName: "A"),
                                     body: .Variable(name: "x", index: 0)))
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
                                      parameterType: .Base(typeName: "A"),
                                      body: .Variable(name: "x", index: 0))
    check(input: "\\x:A.x", expectedTerm: expected)
  }

  func testAbsAbsSequence() {
    let expected: Term = .Application(left: .Abstraction(parameter: "x",
                                                         parameterType: .Function(parameterType: .Boolean, returnType: .Unit),
                                                         body: .Application(left: .Variable(name: "x", index: 0),
                                                                            right: .True)),
                                      right: .Abstraction(parameter: "y",
                                                          parameterType: .Boolean,
                                                          body: .Unit))
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit ; (\\x:bool->unit.x true) \\y:bool.unit",
          expectedTerm: .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: expected),
                                     right: expected))
  }

  func testAs() {
    check(input: "x as bool",
          expectedResult: .success(["x":0], .Application(left: .Abstraction(parameter: "x",
                                                                            parameterType: .Boolean,
                                                                            body: .Variable(name: "x", index: 0)),
                                                         right: .Variable(name: "x", index: 0))))
  }

  func testAsLambda() {
    let body: Term = .Abstraction(parameter: "x", parameterType: .Boolean, body: .Unit)
    let expected: Term = .Application(left: .Abstraction(parameter: "x",
                                                         parameterType: .Function(parameterType: .Boolean, returnType: .Unit),
                                                         body: .Variable(name: "x", index: 0)),
                                      right: body)
    check(input: "(\\x:bool.unit) as bool->unit", expectedTerm: expected)
  }

  func testLet() {
    let t1: Term = .Zero
    let t2: Term = .Abstraction(parameter: "y",
                                parameterType: .Integer,
                                body: .Application(left: .Variable(name: "y", index: 0),
                                                   right: .Variable(name: "x", index: 1)))
    let expected: Term = .Application(left: .Abstraction(parameter: "x", parameterType: .Integer, body: t2),
                                      right: t1)
    check(input: "let x=0 in \\y:int.y x", expectedResult: .success(["x":0], expected))
  }

  func testLetApp() {
    let t1: Term = .Abstraction(parameter: "z",
                                parameterType: .Function(parameterType: .Boolean, returnType: .Integer),
                                body: .Application(left: .Variable(name: "z", index: 0),
                                                   right: .True))
    let t2: Term = .Application(left: .Variable(name: "e", index: 0),
                                right: .Abstraction(parameter: "y", parameterType: .Boolean, body: .Zero))
    let expected: Term = .Application(left: .Abstraction(parameter: "e",
                                                         parameterType: .Function(parameterType: .Function(parameterType: .Boolean,
                                                                                                           returnType: .Integer),
                                                                                  returnType: .Integer),
                                                         body: t2),
                                      right: t1)
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expectedResult: .success(["e":0], expected))
  }

  func testWildcard() {
    let expected: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Boolean, body: .Unit), right: .True)
    check(input: "(\\_:bool.unit) true", expectedTerm: expected)
  }

  func testAscription() {
    check(input: "0 as int", expectedTerm: .Application(left: .Abstraction(parameter: "x", parameterType: .Integer, body: .Variable(name: "x", index: 0)), right: .Zero))
  }

}
