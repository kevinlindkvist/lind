import XCTest
@testable import FullSimple

class EvaluationTests: XCTestCase {
  /// Tests that an application where the left hand side is the identity function
  /// returns the right hand side.
  func testIdentityFunction() {
    let expectation: Term = .Abstraction(parameter: "y",
                                          parameterType: .Unit,
                                          body: .Variable(name: "y", index: 0))
    let program = "(\\x:unit->unit.x) \\y:unit.y"
    check(input: program, expectEvaluated: expectation)
  }

  /// Tests that evaluating a b c is evaluated as (a b) c.
  func testEvaluateAssociativity() {
    let program = "(\\x:bool->bool.\\z:int.z) (\\y:bool.y) 0"
    check(input: program, expectEvaluated: .Zero)
  }

  /// Tests evaluating a constant function with an unbound named term.
  func testEvaluateConstant() {
    let expectation: Term = .Variable(name: "x", index: 0)
    let program = "(\\z:unit->unit.x) \\z:unit.z"
    check(input: program, expectEvaluated: expectation)
  }

  func testEvaluateIdentifier() {
    let expectation: Term = .Abstraction(parameter: "y",
                                         parameterType: .Unit,
                                         body: .Variable(name: "y", index: 0))
    let program = "(\\z:unit->unit->unit.z \\y:unit.y) \\x:unit->unit.x"
    check(input: program, expectEvaluated: expectation)
  }

  func testEvaluateWildCard() {
    let expectation: Term = .Unit
    let program = "(\\_:bool.unit) true"
    check(input: program, expectEvaluated: expectation)
  }
  
  func testAscription() {
    check(input: "0 as int", expectEvaluated: .Zero)
  }

  func testTuple() {
    check(input: "{0, unit,true}", expectEvaluated: .Tuple(["0":.Zero,"1":.Unit,"2":.True]))
  }

  func testEmptyTuple() {
    check(input: "{}", expectEvaluated: .Tuple([:]))
  }

  func testTupleProjection() {
    check(input: "{true}.0", expectEvaluated: .True)
  }

  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expectEvaluated: .Tuple(["0":.Zero,"7":.Unit,"2":.True]))
  }

  func testTupleNonValue() {
    check(input: "{(\\x:bool.0) true}", expectEvaluated: .Tuple(["0":.Zero]))
  }

  func testTupleVariable() {
    check(input: "let x=0 in {x}.0", expectEvaluated: .Zero)
  }

  func testLabeledTupleProjection() {
    check(input: "{0, 7:unit,true}.7", expectEvaluated: Term.Unit)
    check(input: "{0, 7:unit,true}.0", expectEvaluated: .Zero)
  }

  func testLet() {
    check(input: "let x=0 in x", expectEvaluated: .Zero)
  }

  func testLetNested() {
    check(input: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expectEvaluated: .Zero)
  }

  func testLetRecordPattern() {
    check(input: "let {x,y}={0,true} in (\\z:bool.z) y", expectEvaluated: .True)
  }

  func testLetRecordPatternMultipleUse() {
    check(input: "let {x,y}={\\x:int.x,0} in x ((\\z:int.z) y)", expectEvaluated: .Zero)
  }

  func testLetRecordPatternMultipleUseLabeled() {
    check(input: "let {wah:x,nah:y}={nah:0, wah:\\x:int.x} in x ((\\z:int.z) y)", expectEvaluated: .Zero)
  }

  func testLetRecordPatternNested() {
    check(input: "let {x,{y}}={0,{true}} in (\\z:bool.z) y", expectEvaluated: .True)
  }
  
  func testLetVariablePattern() {
    check(input: "let x={0,true} in x.0", expectEvaluated: .Zero)
    check(input: "let x={0,true} in x.1", expectEvaluated: .True)
  }

  func testLetShadowing() {
    check(input: "let x=0 in let x=true in let x=unit in x", expectEvaluated: Term.Unit)
  }

  func testLetDeep() {
    check(input: "let x=0 in let y=true in let z=unit in x", expectEvaluated: .Zero)
  }
  
  func testLetDeeper() {
    check(input: "let x={0} in let y=true in let z=unit in x.0", expectEvaluated: .Zero)
  }
  
  func testLetDeepest() {
    check(input: "let x={0} in let y=x in let z=y in z.0", expectEvaluated: .Zero)
  }

  func testNestedProjection() {
    check(input: "let x={unit, a:{b:{c:0,d:true}, false}} in x.a.b.c", expectEvaluated: .Zero)
  }

  func testVariantCasesFirst() {
    check(input: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expectEvaluated: .Zero)
  }

  func testVariantCasesSecond() {
    check(input: "case <b=unit> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expectEvaluated: Term.Unit)
  }

  func testVariableAssignment() {
    check(input: "x = 0; x", expectEvaluated: .Zero)
  }

  func testVariableAssignmentNested() {
    check(input: "x = 0; y = true; y", expectEvaluated: .True)
  }

  func testVariableAssignmentNestedOuter() {
    check(input: "x = 0; y = true; x", expectEvaluated: .Zero)
  }

  func testFix() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x)); iseven = fix ff; iseven 0"
    check(input: program, expectEvaluated: .True)
  }
  
  func testFixRecursionDepths() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x)); iseven = fix ff; iseven "
    let four = "succ succ succ succ 0"
    let five = "succ succ succ succ succ 0"
    let anotherFour = "succ pred succ succ succ succ 0"
    check(input: program + four, expectEvaluated: .True)
    check(input: program + five, expectEvaluated: .False)
    check(input: program + anotherFour, expectEvaluated: .True)
  }

  func testMutualRecursion() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}.{iseven : \\x:int.if isZero x then true else ieio.isodd (pred x), isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)}; r = fix ff; iseven = r.iseven; iseven "
    let zero = "0"
    let one = "succ 0"
    check(input: program + zero, expectEvaluated: .True)
    check(input: program + one, expectEvaluated: .False)
  }

  func testMutualRecursionDepth() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}.{iseven : \\x:int.if isZero x then true else ieio.isodd (pred x), isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)}; r = fix ff; iseven = r.iseven; iseven "
    let four = "succ succ succ succ 0"
    let five = "succ succ succ succ succ 0"
    let anotherFour = "succ pred succ succ succ succ 0"
    check(input: program + four, expectEvaluated: .True)
    check(input: program + five, expectEvaluated: .False)
    check(input: program + anotherFour, expectEvaluated: .True)
  }

}
