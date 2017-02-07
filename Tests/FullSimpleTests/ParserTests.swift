//
//  ParserTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/7/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import XCTest
import Parswift
@testable import FullSimple

class ParserTests: XCTestCase {

  fileprivate func check(input: String, expectedTerm: Term) {
    check(input: input, expectedResult: .right(expectedTerm))
  }

  fileprivate func check(input: String, expectedResult: Either<ParseError, Term>) {
    let result = parse(input: input, terms: [:])
    switch (result, expectedResult) {
    case let (.right(t1), .right(t2)):
      XCTAssertEqual(t1, t2, "\n\(t1)\n\(t2)")
    case (.left, .left):
      break
    case let (.left(error), .right):
      XCTFail("Unexpected parser failure for \(input): \(error)")
    default:
      XCTFail("Succeded in parsing \(result) when expecting failure.")
    }
  }

  func parseError() -> ParseError {
    return ParseError(position: SourcePosition(name: "", line: 1, column: 1), messages: [])
  }

  func testAbsBaseType() {
    let expected: Term = .Abstraction(parameter: "x",
                                      parameterType: .Boolean,
                                      body: .Variable(name: "x", index: 0))
    check(input: "\\x:bool.x", expectedTerm: expected)
  }

  func testAppSpaces() {
    let expected: Term = .Application(left: .Variable(name: "a", index: 0), right: .Variable(name: "b", index: 1))
    check(input: "a b", expectedResult: .right(expected))
    check(input: "a  b", expectedResult: .right(expected))
    check(input: "a     b", expectedResult: .right(expected))
    check(input: "ab", expectedResult: .right(.Variable(name: "ab", index: 0)))
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
          expectedResult: .right(expected))
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
    check(input: "a b; c d", expectedResult: .right(expected))
    check(input: "a b ;c d", expectedResult: .right(expected))
    check(input: "a b; c d", expectedResult: .right(expected))
    check(input: "a b ; c d", expectedResult: .right(expected))
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
          expectedResult: .right(.Application(left: .Abstraction(parameter: "x",
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

  func testLetSimple() {
    let t1: Term = .Zero
    let t2: Term = .Variable(name: "x", index: 0)
    let expected: Term = .Pattern(pattern: .Variable(name: "x"), argument: t1, body: t2)
    check(input: "let x = 0 in x", expectedResult: .right(expected))
  }

  func testLet() {
    let t1: Term = .Zero
    let t2: Term = .Abstraction(parameter: "y",
                                parameterType: .Integer,
                                body: .Application(left: .Variable(name: "y", index: 0),
                                                   right: .Variable(name: "x", index: 1)))
    let expected: Term =  .Pattern(pattern: .Variable(name: "x"), argument: t1, body: t2)
    check(input: "let x=0 in \\y:int.y x", expectedResult: .right(expected))
  }

  func testLetApp() {
    let t1: Term = .Abstraction(parameter: "z",
                                parameterType: .Function(parameterType: .Boolean, returnType: .Integer),
                                body: .Application(left: .Variable(name: "z", index: 0),
                                                   right: .True))
    let t2: Term = .Application(left: .Variable(name: "e", index: 0),
                                right: .Abstraction(parameter: "y", parameterType: .Boolean, body: .Zero))
    let expected: Term = .Pattern(pattern: .Variable(name: "e"), argument: t1, body: t2)
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expectedResult: .right(expected))
  }

  func testWildcard() {
    let expected: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Boolean, body: .Unit), right: .True)
    check(input: "(\\_:bool.unit) true", expectedTerm: expected)
  }

  func testAscription() {
    check(input: "0 as int", expectedTerm: .Application(left: .Abstraction(parameter: "x", parameterType: .Integer, body: .Variable(name: "x", index: 0)), right: .Zero))
  }

  func testTuple() {
    check(input: "{0, unit,true}", expectedTerm: .Tuple(["1":.Zero,"2":.Unit,"3":.True]))
  }

  func testEmptyTuple() {
    check(input: "{}", expectedTerm: .Tuple([:]))
  }

  func testTupleNonValue() {
    let expected: Term = .Application(left: .Abstraction(parameter: "x", parameterType: .Boolean, body: .Zero), right: .True)
    check(input: "{(\\x:bool.0) true}", expectedTerm: .Tuple(["1":expected]))
  }

  func testTupleProjection() {
    check(input: "{true}.1", expectedTerm: .Pattern(pattern: .Record(["1":.Variable(name: "$")]), argument: .Tuple(["1":.True]), body: .Variable(name: "$", index: 0)))
  }

  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expectedTerm: .Tuple(["1":.Zero,"7":.Unit,"3":.True]))
  }

  func testPatternMatching() {
    let expected: Term = .Pattern(pattern: .Record(["1":.Variable(name: "x"), "2":.Variable(name: "y")]), argument: .Tuple(["1":.Zero, "2":.True]), body: .Variable(name: "x", index: 0))
    check(input: "let {x, y}={0,true} in x", expectedTerm: expected)
  }

  func testLetNested() {
    let inner: Term = .Application(left: .Abstraction(parameter: "z", parameterType: .Function(parameterType: .Integer, returnType: .Integer), body: .Variable(name: "z", index: 0)),
                                   right: .Abstraction(parameter: "y", parameterType: .Integer, body: .Variable(name: "y", index: 0)))
    let outer: Term = .Application(left: inner, right: .Variable(name: "x", index: 0))
    let expected: Term = .Pattern(pattern: .Variable(name: "x"), argument: .Zero, body: outer)
    check(input: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expectedTerm: expected)
  }

  func testProductType() {
    check(input: "\\x:{int, bool}.x", expectedTerm: .Abstraction(parameter: "x", parameterType: .Product(["1":.Integer,"2":.Boolean]), body: .Variable(name: "x", index: 0)))
  }

  func testLetVariablePattern() {
    let inner: Term = .Pattern(pattern: .Record(["1":.Variable(name: "$")]), argument: .Variable(name: "x", index: 0), body: .Variable(name: "$", index: 0))
    let outer: Term = .Pattern(pattern: .Variable(name: "x"), argument: .Tuple(["1":.Zero, "2":.True]), body: inner)
    print(outer)
    check(input: "let x={0,true} in x.1", expectedTerm: outer)
  }

}
