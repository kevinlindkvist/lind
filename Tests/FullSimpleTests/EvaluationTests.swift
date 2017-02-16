//
//  EvaluationTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 1/18/17.
//  Copyright © 2017 lindkvist. All rights reserved.
//

import XCTest
@testable import FullSimple

class EvaluationTests: XCTestCase {

  func check(program: String, expectation: Term) {
    switch parse(input: program, terms: ParseContext(terms: [:], types: [:], namedTypes: [:], namedTerms: [])) {
      case let .right(term, _):
        print("\(term)")
        XCTAssertEqual(evaluate(term: term), expectation)
      case let .left(error): XCTAssertTrue(false, "Could not parse \(program): \(error)")
    }
  }

  func testEvaluate() {
    let expectation: Term = .Abstraction(parameter: "y",
                                         parameterType: .Unit,
                                         body: .Variable(name: "y", index: 0))
    let program = "(\\x:unit.x) \\y:unit.y"
    check(program: program, expectation: expectation)
  }

  func testEvaluateConstant() {
    let expectation: Term = .Variable(name: "x", index: 0)
    let program = "(\\z:unit->unit.x) \\z:unit.z"
    check(program: program, expectation: expectation)
  }

  func testEvaluateConstantBaseType() {
    let expectation: Term = .Variable(name: "x", index: 0)
    let program = "(\\z:A->A.x) \\z:A.z"
    check(program: program, expectation: expectation)
  }

  func testEvaluateIdentifier() {
    let expectation: Term = .Abstraction(parameter: "y",
                                         parameterType: .Unit,
                                         body: .Variable(name: "y", index: 0))
    let program = "(\\z:unit->unit->unit.z \\y:unit.y) \\x:unit->unit.x"
    check(program: program, expectation: expectation)
  }

  func testEvaluateWildCard() {
    let expectation: Term = .Unit
    let program = "(\\_:bool.unit) true"
    check(program: program, expectation: expectation)
  }
  
  func testAscription() {
    check(program: "0 as int", expectation: .Zero)
  }

  func testTuple() {
    check(program: "{0, unit,true}", expectation: .Tuple(["0":.Zero,"1":.Unit,"2":.True]))
  }

  func testEmptyTuple() {
    check(program: "{}", expectation: .Tuple([:]))
  }

  func testTupleProjection() {
    check(program: "{true}.0", expectation: .True)
  }

  func testLabeledTuple() {
    check(program: "{0, 7:unit,true}", expectation: .Tuple(["0":.Zero,"7":.Unit,"2":.True]))
  }

  func testTupleNonValue() {
    check(program: "{(\\x:bool.0) true}", expectation: .Tuple(["0":.Zero]))
  }

  func testTupleVariable() {
    check(program: "let x=0 in {x}.0", expectation: .Zero)
  }

  func testLabeledTupleProjection() {
    check(program: "{0, 7:unit,true}.7", expectation: .Unit)
    check(program: "{0, 7:unit,true}.0", expectation: .Zero)
  }

  func testLet() {
    check(program: "let x=0 in x", expectation: .Zero)
  }

  func testLetNested() {
    check(program: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expectation: .Zero)
  }

  func testLetRecordPattern() {
    check(program: "let {x,y}={0,true} in (\\z:bool.z) y", expectation: .True)
  }

  func testLetRecordPatternMultipleUse() {
    check(program: "let {x,y}={\\x:int.x,0} in x ((\\z:int.z) y)", expectation: .Zero)
  }

  func testLetRecordPatternMultipleUseLabeled() {
    check(program: "let {wah:x,nah:y}={nah:0, wah:\\x:int.x} in x ((\\z:int.z) y)", expectation: .Zero)
  }

  func testLetRecordPatternNested() {
    check(program: "let {x,{y}}={0,{true}} in (\\z:bool.z) y", expectation: .True)
  }
  
  func testLetVariablePattern() {
    check(program: "let x={0,true} in x.0", expectation: .Zero)
    check(program: "let x={0,true} in x.1", expectation: .True)
  }

  func testLetShadowing() {
    check(program: "let x=0 in let x=true in let x=unit in x", expectation: .Unit)
  }

  func testLetDeep() {
    check(program: "let x=0 in let y=true in let z=unit in x", expectation: .Zero)
  }
  
  func testLetDeeper() {
    check(program: "let x={0} in let y=true in let z=unit in x.0", expectation: .Zero)
  }
  
  func testLetDeepest() {
    check(program: "let x={0} in let y=x in let z=y in z.0", expectation: .Zero)
  }

  func testNestedProjection() {
    check(program: "let x={unit, a:{b:{c:0,d:true}, false}} in x.a.b.c", expectation: .Zero)
  }

  func testVariantCasesFirst() {
    check(program: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expectation: .Zero)
  }

  func testVariantCasesSecond() {
    check(program: "case <b=unit> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expectation: .Unit)
  }

}
