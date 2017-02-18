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
    check(input: program, expect: expectation)
  }

  /// Tests that evaluating a b c is evaluated as (a b) c.
  func testEvaluateAssociativity() {
    let program = "(\\x:bool->bool.\\z:int.z) (\\y:bool.y) 0"
    check(input: program, expect: .Zero)
  }

  /// Tests evaluating a constant function with an unbound named term.
  func testEvaluateConstant() {
    let expectation: Term = .Variable(name: "x", index: 0)
    let program = "(\\z:unit->unit.x) \\z:unit.z"
    check(input: program, expect: expectation)
  }

  func testEvaluateIdentifier() {
    let expectation: Term = .Abstraction(parameter: "y",
                                         parameterType: .Unit,
                                         body: .Variable(name: "y", index: 0))
    let program = "\\z:unit->unit->unit.z \\y:unit.y \\x:unit->unit.x"
    check(input: program, expect: expectation)
  }

  func testEvaluateWildCard() {
    let expectation: Term = .Unit
    let program = "(\\_:bool.unit) true"
    check(input: program, expect: expectation)
  }
  
  func testAscription() {
    check(input: "0 as int", expect: .Zero)
  }

  func testTuple() {
    check(input: "{0, unit,true}", expect: .Tuple(["0":.Zero,"1":.Unit,"2":.True]))
  }

  func testEmptyTuple() {
    check(input: "{}", expect: .Tuple([:]))
  }

  func testTupleProjection() {
    check(input: "{true}.0", expect: .True)
  }

  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expect: .Tuple(["0":.Zero,"7":.Unit,"2":.True]))
  }

  func testTupleNonValue() {
    check(input: "{(\\x:bool.0) true}", expect: .Tuple(["0":.Zero]))
  }

  func testTupleVariable() {
    check(input: "let x=0 in {x}.0", expect: .Zero)
  }

  func testLabeledTupleProjection() {
    check(input: "{0, 7:unit,true}.7", expect: Term.Unit)
    check(input: "{0, 7:unit,true}.0", expect: .Zero)
  }

  func testLet() {
    check(input: "let x=0 in x", expect: .Zero)
  }

  func testLetNested() {
    check(input: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expect: .Zero)
  }

  func testLetRecordPattern() {
    check(input: "let {x,y}={0,true} in (\\z:bool.z) y", expect: .True)
  }

  func testLetRecordPatternMultipleUse() {
    check(input: "let {x,y}={\\x:int.x,0} in x ((\\z:int.z) y)", expect: .Zero)
  }

  func testLetRecordPatternMultipleUseLabeled() {
    check(input: "let {wah:x,nah:y}={nah:0, wah:\\x:int.x} in x ((\\z:int.z) y)", expect: .Zero)
  }

  func testLetRecordPatternNested() {
    check(input: "let {x,{y}}={0,{true}} in (\\z:bool.z) y", expect: .True)
  }
  
  func testLetVariablePattern() {
    check(input: "let x={0,true} in x.0", expect: .Zero)
    check(input: "let x={0,true} in x.1", expect: .True)
  }

  func testLetShadowing() {
    check(input: "let x=0 in let x=true in let x=unit in x", expect: Term.Unit)
  }

  func testLetDeep() {
    check(input: "let x=0 in let y=true in let z=unit in x", expect: .Zero)
  }
  
  func testLetDeeper() {
    check(input: "let x={0} in let y=true in let z=unit in x.0", expect: .Zero)
  }
  
  func testLetDeepest() {
    check(input: "let x={0} in let y=x in let z=y in z.0", expect: .Zero)
  }

  func testNestedProjection() {
    check(input: "let x={unit, a:{b:{c:0,d:true}, false}} in x.a.b.c", expect: .Zero)
  }

  func testVariantCasesFirst() {
    check(input: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expect: .Zero)
  }

  func testVariantCasesSecond() {
    check(input: "case <b=unit> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expect: Term.Unit)
  }

  func testVariableAssignment() {
    check(input: "x = 0; x", expect: .Zero)
  }

  func testVariableAssignmentNested() {
    check(input: "x = 0; y = true; y", expect: .True)
  }

  func testVariableAssignmentNestedOuter() {
    check(input: "x = 0; y = true; x", expect: .Zero)
  }

  func testFix() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x)); iseven = fix ff; iseven 0"
    check(input: program, expect: .True)
  }
  
  func testFixRecursionDepths() {
    let program = "ff = \\ie:int->bool.\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x)); iseven = fix ff; iseven "
    let four = "succ succ succ succ 0"
    let five = "succ succ succ succ succ 0"
    let anotherFour = "succ pred succ succ succ succ 0"
    check(input: program + four, expect: .True)
    check(input: program + five, expect: .False)
    check(input: program + anotherFour, expect: .True)
  }

  func testMutualRecursion() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}.{iseven : \\x:int.if isZero x then true else ieio.isodd (pred x), isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)}; r = fix ff; iseven = r.iseven; iseven "
    let zero = "0"
    let one = "succ 0"
    check(input: program + zero, expect: .True)
    check(input: program + one, expect: .False)
  }

  func testMutualRecursionDepth() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}.{iseven : \\x:int.if isZero x then true else ieio.isodd (pred x), isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)}; r = fix ff; iseven = r.iseven; iseven "
    let four = "succ succ succ succ 0"
    let five = "succ succ succ succ succ 0"
    let anotherFour = "succ pred succ succ succ succ 0"
    check(input: program + four, expect: .True)
    check(input: program + five, expect: .False)
    check(input: program + anotherFour, expect: .True)
  }

}
