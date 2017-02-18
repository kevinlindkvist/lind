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

  /// Tests the type of a named variable.
  func testVariable() {
    check(input: "x", expect: .Integer, with:[0:.Integer])
  }

  /// Tests the type of an unnamed variable.
  func testUnnamedVariable() {
    check(input: "x", expect: .left(.message("")))
  }

  /// Tests the type of an abstraction.
  func testAbstraction() {
    check(input: "\\x:bool.x", expect: .Function(parameterType: .Boolean, returnType: .Boolean))
  }

  /// Tests the type of an application.
  func testApplication() {
    check(input: "(\\x:bool.x) true", expect: .Boolean)
  }

  /// Tests the misuse of a parameter in the body.
  func testIncorrectParameterUse() {
    check(input: "\\x:bool.x x", expect: .left(.message("")))
  }

  /// Tests a parameter type missmatch.
  func testIncorrectArgumentType() {
    check(input: "(\\x:bool.x) 0", expect: .left(.message("")))
  }

  /// Tests that application type checking has the correct associativity.
  func testAssociativity() {
    let program = "(\\x:bool->bool.\\z:int.z) (\\y:bool.y) 0"
    check(input: program, expect: .Integer)
    check(input: "(\\x:bool->bool.\\z:int.z) ((\\y:bool.y) 0)", expect: .left(.message("")))
  }

  /// Tests isZero with an natural number parameter.
  func testIsZero() {
    check(input: "isZero succ 0", expect: .Boolean)
  }

  /// Tests isZero with a non-integer parameter.
  func testIncorrectIsZero() {
    check(input: "isZero isZero 0", expect: .left(.message("")))
  }

  /// Tests succ and pred of a natural number.
  func testSucc() {
    check(input: "pred succ 0", expect: .Integer)
  }

  /// Tests pred of an incorrect argument type.
  func testIncorrect() {
    check(input: "pred isZero 0", expect: .left(.message("")))
  }

  /// Tests the type of 0.
  func testZero() {
    check(input: "0", expect: .Integer)
  }

  /// Tests the type of an if else with matching case types.
  func testIfElse() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    check(input: correctIfElse, expect: .Integer)
  }

  /// Tests the type of an if else with cases of different type.
  func testIfElseCaseMissmatch() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let incorrectIfElse = "if \(firstConditional) then \(thenClause) else true"
    check(input: incorrectIfElse, expect: .left(.message("")))
  }

  /// Tests the type of a nested abstraction.
  func testNestedAbstraction() {
    check(input: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", expect:Type.Unit)
  }

  /// Tests the type of an applied abstration with a function type parameter.
  func testAbsUnit() {
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit", expect:Type.Unit)
  }

  // MARK - Base Type

  /// Tests the type of an abstraction with a base type parameter.
  func testBaseType() {
    check(input: "\\x:A.x",
          expect: .Function(parameterType: .Base(typeName: "A"), returnType: .Base(typeName: "A")))
  }

  /// Tests a parameter type missmatch with a base type.
  func testBaseTypeInvalidArgument() {
    check(input: "(\\x:A.x) 0", expect: .left(.message("")))
  }

  /// MARK - Sequence

  /// Tests sequencing of a unit typed term.
  func testSequence() {
    check(input: "unit;0", expect: .Integer)
  }

  /// Tests sequencing of a non-unit typed term.
  func testNonUnitSequence() {
    check(input: "true;0", expect: .left(.message("")))
  }

  /// Tests sequencing an abstraction that has a return type of unit.
  func testAbstractionSequence() {
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit; false", expect: .Boolean)
  }

  /// Tests sequencing with applications on both sides.
  func testAbsAbsSequence() {
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit;(\\x:bool->unit.x true) \\y:bool.unit",
          expect:Type.Unit)
  }

  /// Tests a matching ascription.
  func testAs() {
    check(input: "x as bool", expect: .Boolean, with: [0: .Boolean])
  }

  /// Tests an ascription that does not match the type of the term.
  func testAsIncorrectType() {
    check(input: "x as bool", expect: .left(.message("")), with: [0: .Integer])
  }

  func testAsLambda() {
    check(input: "(\\x:bool.unit) as bool->unit",
          expect: .Function(parameterType: .Boolean, returnType:Type.Unit))
  }

  func testLet() {
    check(input: "let x=0 in \\y:int.y x", expect: .left(.message("")))
    check(input: "let x=0 in \\y:int.y", expect: .Function(parameterType: .Integer, returnType: .Integer))
  }

  func testLetApp() {
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expect: .Integer)
  }

  func testWildcard() {
    check(input: "(\\_:bool.unit) true", expect:Type.Unit)
  }

  func testAscription() {
    check(input: "0 as int", expect: .Integer)
  }

  func testAscriptionArgument() {
    check(input: "(\\x:int.x) (0 as int)", expect: .Integer)
    check(input:"(\\x:int.x) (0 as bool)", expect: .left(.message("")))
  }

  func testTuple() {
    check(input: "{0, unit,true}", expect: .Product(["0":.Integer, "1":.Unit, "2":.Boolean]))
  }

  func testEmptyTuple() {
    check(input: "{}", expect: .Product([:]))
  }

  func testTupleNonValue() {
    check(input: "{(\\x:bool.0) true}", expect: .Product(["0":.Integer]))
  }

  func testTupleProjection() {
    check(input: "{true}.0", expect: .Boolean)
  }

  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expect: .Product(["0":.Integer,"7":.Unit,"2":.Boolean]))
  }

  func testInvalidTupleProjection() {
    check(input: "{true}.1", expect: .left(.message("")))
    check(input: "{true}.2", expect: .left(.message("")))
  }
  
  func testTupleArgument() {
    check(input: "(\\x:bool.x) {true}.0", expect: .Boolean)
  }
  
  func testInvalidTupleArgument() {
    check(input: "(\\x:int.x) {true}.0", expect: .left(.message("")))
  }
  
  func testLabeledTupleProjection() {
    check(input: "{0, 7:unit,true}.7", expect: Type.Unit)
    check(input: "{0, 7:unit,true}.0", expect: .Integer)
    check(input: "{0, 7:unit,true}.2", expect: .Boolean)
  }

  func testLetNested() {
    check(input: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expect: .Integer)
  }

  func testLetRecordPattern() {
    check(input: "let {x,y}={0,true} in (\\z:bool.z) y", expect: .Boolean)
    check(input:"let {x,y}={0,{true}} in (\\z:bool.z) y", expect: .left(.message("")))
  }
  
  func testLetRecordNested() {
    check(input: "let {x,{y}}={0,{true}} in (\\z:bool.z) y", expect: .Boolean)
  }
  
  func testLetVariablePattern() {
    check(input: "let x={0,true} in x.0", expect: .Integer)
    check(input: "let x={0,true} in x.1", expect: .Boolean)
  }

  func testLetShadowing() {
    check(input: "let x=0 in let x=true in let x=unit in x", expect:Type.Unit)
  }

  func testLetDeep() {
    check(input: "let x=0 in let y=true in let z=unit in x", expect: .Integer)
  }
  
  func testLetDeeper() {
    check(input: "let x={0} in let y=true in let z=unit in x", expect: .Product(["0":.Integer]))
    check(input: "let x={0} in let y=x in let z=y in x.0", expect: .Integer)
  }

  func testLetDeepest() {
    check(input: "let x={0} in let y=x in let z=y in x", expect: .Product(["0":.Integer]))
    check(input: "let x={0} in let y=x in let z=y in y", expect: .Product(["0":.Integer]))
    check(input: "let x={0} in let y=x in let z=y in z", expect: .Product(["0":.Integer]))
    check(input: "let x={0} in let y=x in let z=y in z.0", expect: .Integer)
    check(input: "let x={0} in let y=x in let z=y in g", expect: .left(.message("")))
  }

  func testLetAbstractionSameParameter() {
    check(input: "\\x:bool.let x=0 in x", expect: .Function(parameterType: .Boolean, returnType: .Integer))
    check(input: "let x=0 in \\x:bool.x", expect: .Function(parameterType: .Boolean, returnType: .Boolean))
  }

  func testLetAbstractionDifferentParameter() {
    check(input: "\\x:bool.let y=0 in x", expect: .Function(parameterType: .Boolean, returnType: .Boolean))
  }

  func testLetRecordPatternMultipleUseLabeled() {
    check(input: "let {wah:x,nah:y}={nah:0, wah:\\x:int.x} in x ((\\z:int.z) y)", expect: .Integer)
  }

  func testNestedProjection() {
    check(input: "{{{0}}}.0.0.0", expect: .Integer)
  }

  func testVariantCasesMissmatch() {
    check(input: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expect: .left(.message("")))
  }

  func testVariantCasesFirst() {
    check(input: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => 0", expect: .Integer)
  }

  func testVariantCasesSecond() {
    check(input: "case <b=unit> as <a:int,b:unit> of <a=x> => unit | <b=y> => y", expect:Type.Unit)
  }

  func testVariantCasesInsufficientCases() {
    check(input: "case <b=unit> as <a:int,b:unit> of <b=y> => y", expect: .left(.message("")))
  }

  func testVariantInLambda() {
    check(input: "\\x:<a:int,b:unit>.case x of <a=x> => unit | <b=y> => y", expect: .Function(parameterType: .Sum(["a":.Integer, "b":.Unit]), returnType:Type.Unit))
  }

  func testVariableAssignment() {
    check(input: "x = 0; x", expect: .Integer)
  }

  func testFix() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x)); iseven = fix ff; iseven 0"
    check(input: program, expect: .Boolean)
  }
  
  func testMalformedFix() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x)); iseven = fix ff; iseven true"
    check(input: program, expect: .left(.message("")))
  }

  func testMutualRecursion() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}.{iseven : \\x:int.if isZero x then true else ieio.isodd (pred x), isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)}; r = fix ff; iseven = r.iseven; iseven 0"
    check(input: program, expect: .Boolean)
  }
}
