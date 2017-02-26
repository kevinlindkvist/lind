import XCTest
@testable import FullSimple

class EvaluationTests: XCTestCase {

  // Tests evaluating an application where the argument is an application.
  func testIdentityFunction() {
    let expectation: Term = .abstraction(parameter: "y",
                                          parameterType: .unit,
                                          body: .variable(name: "y", index: 0))
    let program = "(\\x:unit->unit.x) \\y:unit.y"
    check(input: program, expectEvaluated: expectation)
  }

  /// Tests associativity of application; evaluating a b c is evaluated as (a b) c.
  func testEvaluateAssociativity() {
    let program = "(\\x:bool->bool.\\z:int.z) (\\y:bool.y) 0"
    check(input: program, expectEvaluated: .zero)
  }

  /// Tests evaluating a constant function with an unbound named term.
  func testEvaluateConstant() {
    let expectation: Term = .variable(name: "x", index: 0)
    let program = "(\\z:unit->unit.x) \\z:unit.z"
    check(input: program, expectEvaluated: expectation)
  }

  /// Tests evaluating an application where the parameter is a wildcard.
  func testEvaluateWildCard() {
    let expectation: Term = .unit
    let program = "(\\_:bool.unit) true"
    check(input: program, expectEvaluated: expectation)
  }

  /// Tests evaluating an ascribed term.
  func testAscription() {
    check(input: "0 as int", expectEvaluated: .zero)
  }

  // MARK: Tuples

  /// Tests evaluating a tuple containing only values.
  func testTuple() {
    check(input: "{0, unit,true}", expectEvaluated: .tuple(["0":.zero,"1":.unit,"2":.trueTerm]))
  }

  /// Tests evaluating an empty tuple.
  func testEmptyTuple() {
    check(input: "{}", expectEvaluated: .tuple([:]))
  }

  /// Tests evaluating a tuple projection with default labels.
  func testTupleProjection() {
    check(input: "{true}.0", expectEvaluated: .trueTerm)
  }

  /// Tests evaluating a tuple with custom labels.
  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expectEvaluated: .tuple(["0":.zero,"7":.unit,"2":.trueTerm]))
  }

  /// Tests evaluating a tuple with non-value contents.
  func testTupleNonValue() {
    check(input: "{(\\x:bool.0) true}", expectEvaluated: .tuple(["0":.zero]))
  }

  /// Tests using a let-bound variable in a tuple, and the projecting into it.
  func testTupleVariable() {
    check(input: "let x=0 in {x}.0", expectEvaluated: .zero)
  }

  /// Tests evaluating tuple projections into a tuple with custom labels.
  func testLabeledTupleProjection() {
    check(input: "{0, 7:unit,true}.7", expectEvaluated: Term.unit)
    check(input: "{0, 7:unit,true}.0", expectEvaluated: .zero)
  }

  /// Tests evaluating a projection into nested tuples.
  func testNestedProjection() {
    check(input: "let x={unit, a:{b:{c:0,d:true}, false}} in x.a.b.c", expectEvaluated: .zero)
  }

  // MARK: Let

  /// Tests evaluating a let bound variable.
  func testLet() {
    check(input: "let x=0 in x", expectEvaluated: .zero)
  }

  /// Tests using a let bound variable in an application.
  func testLetNested() {
    check(input: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expectEvaluated: .zero)
  }

  /// Tests using a let binding with a record pattern.
  func testLetRecordPattern() {
    check(input: "let {x,y}={0,true} in (\\z:bool.z) y", expectEvaluated: .trueTerm)
  }

  /// Tests using multiple variables in a let bound term with a record pattern.
  func testLetRecordPatternMultipleUse() {
    check(input: "let {x,y}={\\x:int.x,0} in x ((\\z:int.z) y)", expectEvaluated: .zero)
  }

  /// Tests a let binding of a record pattern with custom labels.
  func testLetRecordPatternMultipleUseLabeled() {
    check(input: "let {wah:x,nah:y}={nah:0, wah:\\x:int.x} in x ((\\z:int.z) y)",
          expectEvaluated: .zero)
  }

  /// Tests a let binding where the record pattern contains a nested record.
  func testLetRecordPatternNested() {
    check(input: "let {x,{y}}={0,{true}} in (\\z:bool.z) y", expectEvaluated: .trueTerm)
  }

  /// Tests that a let binding with a variable pattern matches tuples.
  func testLetVariablePattern() {
    check(input: "let x={0,true} in x.0", expectEvaluated: .zero)
    check(input: "let x={0,true} in x.1", expectEvaluated: .trueTerm)
  }

  /// Tests nesting let bindings with the same bound variable name.
  func testLetShadowing() {
    check(input: "let x=0 in let x=true in let x=unit in x", expectEvaluated: Term.unit)
  }

  /// Tests nesting let bindings with different bound variable names.
  func testLetDeep() {
    check(input: "let x=0 in let y=true in let z=unit in x", expectEvaluated: .zero)
  }

  /// Tests nesting let bindings where the outermost bound term is a tuple, and the body is a
  /// projection.
  func testLetDeeper() {
    check(input: "let x={0} in let y=true in let z=unit in x.0", expectEvaluated: .zero)
  }

  /// Tests nested let bindings where each step re-binds the outer variable.
  func testLetDeepest() {
    check(input: "let x={0} in let y=x in let z=y in z.0", expectEvaluated: .zero)
  }

  // MARK: Variants

  /// Tests evaluating a variant case where the first case is selected.
  func testVariantCasesFirst() {
    check(input: "case <a=0> as <a:int,b:unit> of <a=x> => x | <b=y> => y", expectEvaluated: .zero)
  }

  /// Tests evaluating a variant case where the second case is selected.
  func testVariantCasesSecond() {
    check(input: "case <b=unit> as <a:int,b:unit> of <a=x> => x | <b=y> => y",
          expectEvaluated: Term.unit)
  }

  // MARK: Variable binding

  /// Tests binding a variable and then using that variable in a later part of the sequence. 
  func testVariableAssignment() {
    check(input: "x = 0; x", expectEvaluated: .zero)
  }

  /// Tests binding multiple variables in a sequence, and using the latest bound variable.
  func testVariableAssignmentNested() {
    check(input: "x = 0; y = true; y", expectEvaluated: .trueTerm)
  }

  /// Tests binding multiple variables in a sequence, and using the earliest bound variable.
  func testVariableAssignmentNestedOuter() {
    check(input: "x = 0; y = true; x", expectEvaluated: .zero)
  }

  // MARK: Fix

  /// Tests creating a recursive function using the fix operator.
  func testFix() {
    let program = "ff = \\ie:int->bool."
    + "\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x));"
    + "iseven = fix ff; iseven 0"
    check(input: program, expectEvaluated: .trueTerm)
  }

  /// Tests a recursive function with arguments that use differing depths of recursion.
  func testFixRecursionDepths() {
    let program = "ff = \\ie:int->bool."
    + "\\x:int.if isZero x then true else if isZero (pred x) then false else ie (pred (pred x));"
    + "iseven = fix ff; iseven "
    
    let four = "succ succ succ succ 0"
    let five = "succ succ succ succ succ 0"
    let anotherFour = "succ pred succ succ succ succ 0"
    check(input: program + four, expectEvaluated: .trueTerm)
    check(input: program + five, expectEvaluated: .falseTerm)
    check(input: program + anotherFour, expectEvaluated: .trueTerm)
  }

  /// Tests fixing a function with a parameter tuple of mutually recursive functions.
  func testMutualRecursion() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}."
      + "{iseven : \\x:int.if isZero x then true else ieio.isodd (pred x),"
      + "isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)};"
      + "r = fix ff; iseven = r.iseven; iseven "
    let zero = "0"
    let one = "succ 0"
    check(input: program + zero, expectEvaluated: .trueTerm)
    check(input: program + one, expectEvaluated: .falseTerm)
  }

  /// Tests fixing a function with a parameter tuple of mutually recursive functions, called with
  /// arguments that use differing amounts of recursive calls.
  func testMutualRecursionDepth() {
    let program = "ff = \\ieio:{iseven:int->bool, isodd:int->bool}."
      + "{iseven : \\x:int.if isZero x then true else ieio.isodd (pred x),"
      + "isodd : \\x:int.if isZero x then false else ieio.iseven (pred x)};"
      + "r = fix ff; iseven = r.iseven; iseven "
    let four = "succ succ succ succ 0"
    let five = "succ succ succ succ succ 0"
    let anotherFour = "succ pred succ succ succ succ 0"
    check(input: program + four, expectEvaluated: .trueTerm)
    check(input: program + five, expectEvaluated: .falseTerm)
    check(input: program + anotherFour, expectEvaluated: .trueTerm)
  }

}
