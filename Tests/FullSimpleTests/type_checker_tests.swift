import XCTest
import Parser
@testable import FullSimple

class TypeCheckerTests: XCTestCase {

  /// Tests the type of a named variable.
  func testVariable() {
    check(input: "x", expect: .integer, with:[0:.integer])
  }

  /// Tests the type of an unnamed variable.
  func testUnnamedVariable() {
    check(input: "x", expect: .left(.message("")))
  }

  /// Tests the type of an abstraction.
  func testAbstraction() {
    check(input: "\\x:bool.x", expect: .function(parameterType: .boolean, returnType: .boolean))
  }

  /// Tests the type of an application.
  func testApplication() {
    check(input: "(\\x:bool.x) true", expect: .boolean)
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
    check(input: program, expect: .integer)
    check(input: "(\\x:bool->bool.\\z:int.z) ((\\y:bool.y) 0)", expect: .left(.message("")))
  }

  /// Tests isZero with an natural number parameter.
  func testIsZero() {
    check(input: "isZero succ 0", expect: .boolean)
  }

  /// Tests isZero with a non-integer parameter.
  func testIncorrectIsZero() {
    check(input: "isZero isZero 0", expect: .left(.message("")))
  }

  /// Tests succ and pred of a natural number.
  func testSucc() {
    check(input: "pred succ 0", expect: .integer)
  }

  /// Tests pred of an incorrect argument type.
  func testIncorrect() {
    check(input: "pred isZero 0", expect: .left(.message("")))
  }

  /// Tests the type of 0.
  func testZero() {
    check(input: "0", expect: .integer)
  }

  /// Tests the type of an if else with matching case types.
  func testIfElse() {
    let firstConditional = "(\\x:bool.x) true"
    let thenClause = "(\\y:bool->int.y true) \\z:bool.if isZero 0 then succ 0 else pred succ 0"
    let correctIfElse = "if \(firstConditional) then \(thenClause) else 0"
    check(input: correctIfElse, expect: .integer)
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
    check(input: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", expect:Type.unit)
  }

  /// Tests the type of an applied abstration with a function type parameter.
  func testAbsUnit() {
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit", expect:Type.unit)
  }

  // MARK: - Base Type

  /// Tests the type of an abstraction with a base type parameter.
  func testBaseType() {
    check(input: "\\x:A.x",
          expect: .function(parameterType: .base(typeName: "A"), returnType: .base(typeName: "A")))
  }

  /// Tests a parameter type missmatch with a base type.
  func testBaseTypeInvalidArgument() {
    check(input: "(\\x:A.x) 0", expect: .left(.message("")))
  }

  // MARK: - Sequence

  /// Tests sequencing of a unit typed term.
  func testSequence() {
    check(input: "unit;0", expect: .integer)
  }

  /// Tests sequencing of a non-unit typed term.
  func testNonUnitSequence() {
    check(input: "true;0", expect: .left(.message("")))
  }

  /// Tests sequencing an abstraction that has a return type of unit.
  func testAbstractionSequence() {
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit; false", expect: .boolean)
  }

  /// Tests sequencing with applications on both sides.
  func testAbsAbsSequence() {
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit;(\\x:bool->unit.x true) \\y:bool.unit",
          expect:Type.unit)
  }

  // MARK: Ascription

  /// Tests a matching ascription.
  func testAs() {
    check(input: "x as bool", expect: .boolean, with: [0: .boolean])
  }

  /// Tests a matching ascription with a value.
  func testAscription() {
    check(input: "0 as int", expect: .integer)
  }

  /// Tests an ascription that does not match the type of the term.
  func testAsIncorrectType() {
    check(input: "x as bool", expect: .left(.message("")), with: [0: .integer])
  }

  /// Tests ascribing an abstraction.
  func testAsAbstraction() {
    check(input: "(\\x:bool.unit) as bool->unit",
          expect: .function(parameterType: .boolean, returnType:Type.unit))
  }

  /// Tests ascription of an argument to an abstraction.
  func testAscriptionArgument() {
    check(input: "(\\x:int.x) (0 as int)", expect: .integer)
  }

  /// Tests an incorrect ascription as a parameter to an abstraction.
  func testIncorrectAscriptionArgument() {
    check(input:"(\\x:int.x) (0 as bool)", expect: .left(.message("")))
  }

  // MARK: Let

  /// Tests the type of a basic let.
  func testLet() {
    check(input: "let x=0 in \\y:int.y",
          expect: .function(parameterType: .integer, returnType: .integer))
  }

  /// Tests incorrect usage of a let-bound term.
  func testIncorrectLetParameterUse() {
    check(input: "let x=0 in \\y:int.y x", expect: .left(.message("")))
  }

  /// Tests a let where the bound variable is an abstraction.
  func testLetAbstractionApplication() {
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expect: .integer)
  }

  /// Tests the type of a let with a record pattern.
  func testLetRecordPattern() {
    check(input: "let {x,y}={0,true} in (\\z:bool.z) y", expect: .boolean)
  }

  /// Tests incorrect usage of a record pattern entry.
  func testLetPatternIncorrectUsage() {
    check(input:"let {x,y}={0,{true}} in (\\z:bool.z) y", expect: .left(.message("")))
  }

  /// Tests the type of a let with a nested record pattern.
  func testLetRecordNested() {
    check(input: "let {x,{y}}={0,{true}} in (\\z:bool.z) y", expect: .boolean)
  }

  /// Tests the type of a projection into a let with a record pattern.
  func testLetVariablePattern() {
    check(input: "let x={0,true} in x.0", expect: .integer)
    check(input: "let x={0,true} in x.1", expect: .boolean)
  }

  /// Tests the type of multiple lets shadowing each other.
  func testLetShadowing() {
    check(input: "let x=0 in let x=true in let x=unit in x", expect:Type.unit)
  }

  /// Tests the type of multiple lets that don't shadow each other.
  func testMultipleLetNoShadowing() {
    check(input: "let x=0 in let y=true in let z=unit in x", expect: .integer)
  }

  /// Tests the type of multiple lets that don't shadow each other.
  func testMultipleLetPatternNoShadowing() {
    check(input: "let x={0} in let y=true in let z=unit in x", expect: .product(["0":.integer]))
  }

  /// Tests the type of multiple lets with a tuple projection.
  func testMultipleLetPatternProjection() {
    check(input: "let x={0} in let y=x in let z=y in x.0", expect: .integer)
  }

  /// Tests the types of all the parameters in a nested let.
  func testAllNestedLets() {
    check(input: "let x={0} in let y=x in let z=y in x", expect: .product(["0":.integer]))
    check(input: "let x={0} in let y=x in let z=y in y", expect: .product(["0":.integer]))
    check(input: "let x={0} in let y=x in let z=y in z", expect: .product(["0":.integer]))
    check(input: "let x={0} in let y=x in let z=y in z.0", expect: .integer)
    check(input: "let x={0} in let y=x in let z=y in g", expect: .left(.message("")))
  }

  /// Tests the shadowing of let parameters in abstractions.
  func testLetAbstractionSameParameter() {
    check(input: "\\x:bool.let x=0 in x",
          expect: .function(parameterType: .boolean, returnType: .integer))
    check(input: "let x=0 in \\x:bool.x",
          expect: .function(parameterType: .boolean, returnType: .boolean))
  }

  /// Tests a let in a body of an abstraction.
  func testLetAbstractionDifferentParameter() {
    check(input: "\\x:bool.let y=0 in x",
          expect: .function(parameterType: .boolean, returnType: .boolean))
  }

  /// Tests the type of a record pattern with multiple usages.
  func testLetRecordPatternMultipleUseLabeled() {
    check(input: "let {wah:x,nah:y}={nah:0, wah:\\x:int.x} in x ((\\z:int.z) y)", expect: .integer)
  }

  // MARK: Tuples

  /// Tests the type of a basic tuple.
  func testTuple() {
    check(input: "{0, unit,true}", expect: .product(["0":.integer, "1":.unit, "2":.boolean]))
  }

  /// Tests the type of an empty tuple.
  func testEmptyTuple() {
    check(input: "{}", expect: .product([:]))
  }

  /// Tests the type of a tuple with a non-value entry.
  func testTupleNonValue() {
    check(input: "{(\\x:bool.0) true}", expect: .product(["0":.integer]))
  }

  /// Tests the type of a tuple projection.
  func testTupleProjection() {
    check(input: "{true}.0", expect: .boolean)
  }

  /// Tests the type of a tuple with non-default labels.
  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expect: .product(["0":.integer,"7":.unit,"2":.boolean]))
  }

  /// Tests invalid tuple projections.
  func testInvalidTupleProjection() {
    check(input: "{true}.1", expect: .left(.message("")))
    check(input: "{true}.2", expect: .left(.message("")))
  }

  /// Tests the type of a tuple projection as an argument in an application.
  func testTupleProjectionArgument() {
    check(input: "(\\x:bool.x) {true}.0", expect: .boolean)
  }

  /// Tests the type of a tuple projection with incorrect type as an argument to an application.
  func testInvalidTupleArgument() {
    check(input: "(\\x:int.x) {true}.0", expect: .left(.message("")))
  }

  /// Tests the type of all projections in a non-default labeled tuple.
  func testLabeledTupleProjection() {
    check(input: "{0, 7:unit,true}.7", expect: Type.unit)
    check(input: "{0, 7:unit,true}.0", expect: .integer)
    check(input: "{0, 7:unit,true}.2", expect: .boolean)
  }

  /// Tests projection into a nested tuple.
  func testNestedProjection() {
    check(input: "{{{0}}}.0.0.0", expect: .integer)
  }

  // MARK: Variants

  /// Tests a variant with cases that have different types.
  func testVariantCasesMissmatch() {
    check(input: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => y",
          expect: .left(.message("")))
  }

  /// Tests the type of a variant where the first case matches.
  func testVariantCasesFirst() {
    check(input: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => 0", expect: .integer)
  }

  /// Tests the type of a variant where the second case matches.
  func testVariantCasesSecond() {
    check(input: "case <b=unit> as <a:int,b:unit> of <a=x> => unit | <b=y> => y", expect:Type.unit)
  }

  /// Tests the type of a variant with insufficient cases.
  func testVariantCasesInsufficientCases() {
    check(input: "case <b=unit> as <a:int,b:unit> of <b=y> => y", expect: .left(.message("")))
  }

  /// Tests the type of a variant contained in an abstraction.
  func testVariantInAbstraction() {
    check(input: "\\x:<a:int,b:unit>.case x of <a=x> => unit | <b=y> => y",
          expect: .function(parameterType: .sum(["a":.integer, "b":.unit]), returnType:Type.unit))
  }

  /// Tests the type of a named variable after assignment.
  func testVariableAssignment() {
    check(input: "x = 0; x", expect: .integer)
  }

  // MARK: Fix

  /// Tests the type of a fixed abstraction.
  func testFix() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else "
                  + "if isZero (pred x) then false else ie (pred (pred x)); "
                  + "iseven = fix ff; iseven 0"
    check(input: program, expect: .boolean)
  }

  /// Tests the type of an incorrect application of a fixed term.
  func testMalformedFix() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x)); iseven = fix ff; iseven true"
    check(input: program, expect: .left(.message("")))
  }

  /// Tests the type of a fixed abstraction with a record of two mutually recursive abstractions.
  func testMutualRecursion() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}.{"
                  + "iseven : \\x:int.if isZero x then true else ieio.isodd (pred x), "
                  + "isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)}; "
                  + "r = fix ff; iseven = r.iseven; iseven 0"
    check(input: program, expect: .boolean)
  }

  // MARK: Lists

  /// Tests the type of head.
  func testHead() {
    check(input: "head[bool] cons[bool] true nil[bool]", expect: .boolean)
  }

  /// Tests the type of head with a non-list argument.
  func testHeadNonListType() {
    check(input: "head[bool] true", expect: .left(.message("")))
  }

  /// Tests the type of tail.
  func testTail() {
    check(input: "tail[bool] cons[bool] true nil[bool]", expect: .list(contentType: .boolean))
  }

  /// Tests the type of tail with a non-list argument.
  func testTailNonListType() {
    check(input: "tail[bool] 0", expect: .left(.message("")))
  }

  /// Tests the type of isNil.
  func testIsNil() {
    check(input: "isNil[int] nil[int]", expect: .boolean)
  }

  /// Tests the type of isNil when the argument is not a list.
  func testIsNilNonListType() {
    check(input: "isNil[int] 0", expect: .left(.message("")))
  }

  /// Tests the type of a nil list.
  func testNil() {
    check(input: "nil[bool]", expect: .list(contentType: .boolean))
  }

  /// Tests the type of cons.
  func testCons() {
    check(input: "cons[int] 0 cons[int] 0 nil[int]", expect: .list(contentType: .integer))
  }

  /// Tests that the type of cons fails when the types don't match.
  func testConsIncorrectTypes() {
    check(input: "cons[int] 0 cons[bool] 0 nil[int]", expect: .left(.message("")))
    check(input: "cons[int] true cons[int] 0 nil[int]", expect: .left(.message("")))
  }

  /// Tests the type of an abstraction where the parameter type is a list.
  func testListParameter() {
    check(input: "(\\x:[bool].head[bool] x) cons[bool] true nil[bool]", expect: .boolean)
  }

  /// Tests the type of an abstraction where the parameter type is a list and the argument is
  /// an incorrect type.
  func testListParameterMissmatch() {
    check(input: "(\\x:[int].head[int] x) cons[bool] true nil[bool]", expect: .left(.message("")))
  }
}
