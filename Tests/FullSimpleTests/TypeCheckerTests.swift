//
//  TypeCheckerTests.swift
//  lind
//
//  Created by Kevin Lindkvist on 1/19/17.
//  Copyright © 2017 lindkvist. All rights reserved.
//

import XCTest
import Parser
@testable import FullSimple

class TypeCheckerTests: XCTestCase {

  func check(program: String, type: Type, context: TypeContext = [:]) {
    switch parse(input: program, terms: [:]) {
    case let .right(t):
      switch typeOf(term: t, context: context) {
      case let .success(parsedType):
        XCTAssertEqual(type, parsedType.1)
      case let .failure(error):
        XCTFail("Type check failed: \(error)")
      }
    case let .left(error):
      XCTFail("Could not parse program: \(error)")
    }
  }

  func check(malformedProgram: String, context: TypeContext = [:]) {
    switch parse(input: malformedProgram, terms: [:]) {
    case let .right(t):
      switch typeOf(term: t, context: [:]) {
      case .success:
        XCTFail("Type check did not fail on malformed program.")
      default:
        break
      }
    case let .left(error):
      XCTFail("Could not parse program \(error)")
    }
  }

  func testVar() {
    check(malformedProgram: "x")
    check(program: "x", type: .Integer, context:["x":.Integer])
  }

  func testAbs() {
    check(program: "\\x:bool.x", type: .Function(parameterType: .Boolean, returnType: .Boolean))
    check(program: "(\\x:bool.x) true", type: .Boolean)
    check(malformedProgram: "\\x:bool.x x")
    check(malformedProgram: "(\\x:bool.x) 0")
  }

  func testIsZero() {
    check(program: "isZero succ 0", type: .Boolean)
    check(malformedProgram: "isZero isZero 0")
  }

  func testSucc() {
    check(program: "pred succ 0", type: .Integer)
    check(malformedProgram: "pred isZero 0")
  }

  func testZero() {
    check(program: "0", type: .Integer)
  }

  func testIfElse() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    let incorrectIfElse = "if \(firstConditional) then \(thenClause) else true"
    check(program: correctIfElse, type: .Integer)
    check(malformedProgram: incorrectIfElse)
  }

  func testNestedAbs() {
    check(program: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", type: .Unit)
  }

  // MARK - Extensions

  func testBaseType() {
    check(program: "\\x:A.x", type: .Function(parameterType: .Base(typeName: "A"), returnType: .Base(typeName: "A")))
    check(malformedProgram: "(\\x:A.x) nil")
  }

  func testSequence() {
    check(program: "unit;0", type: .Integer)
    check(malformedProgram: "true;0")
  }

  func testAbsUnit() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit", type: .Unit)
  }

  func testAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit; false", type: .Boolean)
  }

  func testAbsAbsSequence() {
    check(program: "(\\x:bool->unit.x true) \\y:bool.unit;(\\x:bool->unit.x true) \\y:bool.unit", type: .Unit)
  }

  func testAs() {
    check(program: "x as bool", type: .Boolean, context: ["x": .Boolean])
    check(malformedProgram: "x as bool", context: ["x": .Integer])
  }

  func testAsLambda() {
    check(program: "(\\x:bool.unit) as bool->unit", type: .Function(parameterType: .Boolean, returnType: .Unit))
  }

  func testLet() {
    check(malformedProgram: "let x=0 in \\y:int.y x")
    check(program: "let x=0 in \\y:int.y", type: .Function(parameterType: .Integer, returnType: .Integer))
  }

  func testLetApp() {
    check(program: "let e=\\z:bool->int.(z true) in e \\y:bool.0", type: .Integer)
  }

  func testWildcard() {
    check(program: "(\\_:bool.unit) true", type: .Unit)
  }

  func testAscription() {
    check(program: "0 as int", type: .Integer)
  }

  func testAscriptionArgument() {
    check(program: "(\\x:int.x) (0 as int)", type: .Integer)
    check(malformedProgram:"(\\x:int.x) (0 as bool)")
  }

  func testTuple() {
    check(program: "{0, unit,true}", type: .Product(["1":.Integer, "2":.Unit, "3":.Boolean]))
  }

  func testEmptyTuple() {
    check(program: "{}", type: .Product([:]))
  }

  func testTupleNonValue() {
    check(program: "{(\\x:bool.0) true}", type: .Product(["1":.Integer]))
  }

  func testTupleProjection() {
    check(program: "{true}.1", type: .Boolean)
  }

  func testLabeledTuple() {
    check(program: "{0, 7:unit,true}", type: .Product(["1":.Integer,"7":.Unit,"3":.Boolean]))
  }

  func testInvalidTupleProjection() {
    check(malformedProgram: "{true}.2", context: [:])
  }
  
  func testTupleArgument() {
    check(program: "(\\x:bool.x) {true}.1", type: .Boolean)
  }
  
  func testInvalidTupleArgument() {
    check(malformedProgram: "(\\x:int.x) {true}.1", context: [:])
  }
  
  func testLabeledTupleProjection() {
    check(program: "{0, 7:unit,true}.7", type: .Unit)
    check(program: "{0, 7:unit,true}.1", type: .Integer)
  }

  func testLetNested() {
    check(program: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", type: .Integer)
  }

  func testLetRecordPattern() {
    check(program: "let {x,y}={0,true} in (\\z:bool.z) y", type: .Boolean)
    check(malformedProgram:"let {x,y}={0,{true}} in (\\z:bool.z) y")
  }
  
  func testLetRecordNested() {
    check(program: "let {x,{y}}={0,{true}} in (\\z:bool.z) y", type: .Boolean)
  }
  
  func testLetVariablePattern() {
    check(program: "let x={0,true} in x.1", type: .Integer)
    check(program: "let x={0,true} in x.2", type: .Boolean)
  }

  func testLetShadowing() {
    check(program: "let x=0 in let x=true in let x=unit in x", type: .Unit)
  }

  func testLetDeep() {
    check(program: "let x=0 in let y=true in let z=unit in x", type: .Integer)
  }
  
  func testLetDeeper() {
    check(program: "let x={0} in let y=true in let z=unit in x", type: .Product(["1":.Integer]))
    check(program: "let x={0} in let y=x in let z=y in x.1", type: .Integer)
  }

  func testLetDeepest() {
    check(program: "let x={0} in let y=x in let z=y in x", type: .Product(["1":.Integer]))
    check(program: "let x={0} in let y=x in let z=y in y", type: .Product(["1":.Integer]))
    check(program: "let x={0} in let y=x in let z=y in z", type: .Product(["1":.Integer]))
    check(program: "let x={0} in let y=x in let z=y in z.1", type: .Integer)
    check(malformedProgram: "let x={0} in let y=x in let z=y in g")
  }

  func testLetAbstractionSameParameter() {
    check(program: "\\x:bool.let x=0 in x", type: .Function(parameterType: .Boolean, returnType: .Integer))
    check(program: "let x=0 in \\x:bool.x", type: .Function(parameterType: .Boolean, returnType: .Boolean))
  }

  func testLetAbstractionDifferentParameter() {
    check(program: "\\x:bool.let y=0 in x", type: .Function(parameterType: .Boolean, returnType: .Boolean))
  }

  func testLetRecordPatternMultipleUseLabeled() {
    check(program: "let {wah:x,nah:y}={nah:0, wah:\\x:int.x} in x ((\\z:int.z) y)", type: .Integer)
  }

  func testNestedProjection() {
    check(program: "{{{0}}}.1.1.1", type: .Integer)
  }
}
