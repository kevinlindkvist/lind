import XCTest
import Parswift
@testable import FullSimple

class ParserTests: XCTestCase {

  /// Tests parsing an abstraction with a parameter with a base type.
  func testAbsBaseType() {
    let expected: Term = .application(left: .abstraction(parameter: "x",
                                                         parameterType: .boolean,
                                                         body: .variable(name: "x", index: 0)),
                                      right: .variable(name: "x", index: 0))
    check(input: "(\\x:bool.x) x", expect: expected)
  }

  /// Tests parsing an application with differing amounts of whitespace.
  func testAppSpaces() {
    let expected: Term = .application(left: .variable(name: "a", index: 0),
                                      right: .variable(name: "b", index: 1))
    
    check(input: "a b", expect: .right(expected))
    check(input: "a  b", expect: .right(expected))
    check(input: "a     b", expect: .right(expected))
    check(input: "a     b;", expect: .right(expected))
    check(input: "ab", expect: .right(.variable(name: "ab", index: 0)))
  }

  /// Tests parsing succ terms.
  func testSucc() {
    let expected: Term = .succ(.pred(.zero))
    check(input: "succ(pred 0)", expect: expected)
    check(input: "succ pred 0", expect: expected)
  }

  /// Tests parsing pred terms.
  func testPred() {
    let expected: Term = .pred(.succ(.zero))
    check(input: "pred(succ 0)", expect: expected)
  }

  /// Tests parsing an abstraction with a complex parameter type.
  func testAbsArrowType() {
    let expected: Term = .abstraction(parameter: "x",
                                      parameterType: .function(parameterType: .integer,
                                                               returnType: .boolean),
                                      body: .variable(name: "x", index: 0))
    check(input: "\\x:int->bool.x", expect: expected)
  }

  /// Tests parsing an if-else statement without any parentheses.
  func testIfElseNoParens() {
    let expected: Term = .ifThenElse(condition: .succ(.pred(.zero)), trueBranch: .falseTerm, falseBranch: .trueTerm)
    check(input: "if succ pred 0 then false else true", expect: expected)
  }

  /// Tests parsing an if-else statement with an application in the conditional. 
  func testIfElseApplicationConditional() {
    let condition: Term = .application(left: .abstraction(parameter: "x",
                                                          parameterType: .boolean,
                                                          body: .variable(name: "x", index: 0)),
                                       right: .trueTerm)
    let expected: Term = .ifThenElse(condition: condition, trueBranch: .falseTerm, falseBranch: .trueTerm)
    check(input: "if (\\x:bool.x) true then false else true", expect: expected)
  }

  func testIfElseNested() {
    let inner: Term = .ifThenElse(condition:
      .abstraction(parameter: "x", parameterType: .boolean, body: .variable(name: "x", index: 0)),
                          trueBranch: .falseTerm,
                          falseBranch: .trueTerm)
    let expected: Term = .ifThenElse(condition: .abstraction(parameter: "x",
                                                     parameterType: .integer,
                                                     body: .application(left: .variable(name: "x", index: 0), right: inner)),
                             trueBranch: .abstraction(parameter: "y",
                                                      parameterType: .function(parameterType: .boolean, returnType: .integer),
                                                      body: .application(left: .variable(name: "y", index: 0),
                                                                         right: .variable(name: "x", index: 1))),
                             falseBranch: .trueTerm)
    check(input: "if \\x:int.x if \\x:bool.x then false else true then \\y:bool->int.y x else true",
          expect: .right(expected))
  }

  func testAppInSucc() {
    let expected: Term = .succ(.succ(.abstraction(parameter: "x",
                                                  parameterType: .function(parameterType: .boolean, returnType: .integer),
                                                  body: .application(left: .variable(name: "x", index: 0),
                                                                     right: .zero))))
    check(input: "(succ (succ (\\x:bool->int.x 0)))", expect: expected)
  }

  func testIfIsZero() {
    let expected: Term = .ifThenElse(condition: .isZero(.zero), trueBranch: .falseTerm, falseBranch: .trueTerm)
    check(input: "if (isZero 0) then false else true", expect: expected)
  }

  func testAppTermInIfClause() {
    let expected: Term = .ifThenElse(condition: .trueTerm,
                             trueBranch: .application(left: .abstraction(parameter: "x",
                                                                         parameterType: .boolean,
                                                                         body: .variable(name: "x", index: 0)),
                                                      right: .trueTerm),
                             falseBranch: .succ(.zero))
    check(input: "if true then (\\x:bool.x) true else succ 0", expect: expected)
  }

  func testNestedAbs() {
    let inner: Term = .abstraction(parameter: "y",
                                   parameterType: .function(parameterType: .boolean, returnType: .unit),
                                   body: .application(left: .variable(name: "y", index: 0),
                                                      right: .variable(name: "x", index: 1)))
    let expected: Term = .application(left: .application(left: .abstraction(parameter: "x",
                                                                            parameterType: .boolean,
                                                                            body: inner),
                                                         right: .trueTerm),
                                      right: .abstraction(parameter: "z", parameterType: .boolean, body: .unit))
    check(input: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", expect: expected)
  }


  func testNestedFunctionApplication() {
    let body: Term = .application(left: .variable(name: "f", index: 1), right: .application(left: .variable(name: "f", index: 1), right: .variable(name: "x", index: 0)))
    let innerTerm: Term = .abstraction(parameter: "x", parameterType: .integer, body: body)
    let outerTerm: Term = .abstraction(parameter: "f", parameterType: .function(parameterType: .integer, returnType: .integer), body: innerTerm)
    check(input: "\\f:int->int.\\x:int.f (f x)", expect: outerTerm)
  }

  func testLambdaBaseType() {
    check(input: "\\x:A.x",
          expect: .abstraction(parameter: "x",
                                     parameterType: .base(typeName: "A"),
                                     body: .variable(name: "x", index: 0)))
  }

  // MARK - Extension Tests

  func testSequenceUnit() {
    let t1: Term = .unit
    let t2: Term = .unit
    check(input:"unit;unit", expect: .application(left: .abstraction(parameter: "_",
                                                                           parameterType: .unit,
                                                                           body: t2),
                                                        right: t1))
  }

  func testSequenceApp() {
    let t1: Term = .application(left: .variable(name: "a", index: 0),
                                right: .variable(name: "b", index: 1))
    // c is at index 3 instead of 2 due to the _ parameter that is used in the sequence's derived form.
    let t2: Term = .application(left: .variable(name: "c", index: 3),
                                right: .variable(name: "d", index: 4))
    let expected: Term = .application(left: .abstraction(parameter: "_", parameterType: .unit, body: t2),
                                      right: t1)
    check(input: "a b; c d", expect: .right(expected))
    check(input: "a b ;c d", expect: .right(expected))
    check(input: "a b; c d", expect: .right(expected))
    check(input: "a b ; c d", expect: .right(expected))
  }

  func testBaseType() {
    let expected: Term = .abstraction(parameter: "x",
                                      parameterType: .base(typeName: "A"),
                                      body: .variable(name: "x", index: 0))
    check(input: "\\x:A.x", expect: expected)
  }

  func testAbsAbsSequence() {
    let expected: Term = .application(left: .abstraction(parameter: "x",
                                                         parameterType: .function(parameterType: .boolean, returnType: .unit),
                                                         body: .application(left: .variable(name: "x", index: 0),
                                                                            right: .trueTerm)),
                                      right: .abstraction(parameter: "y",
                                                          parameterType: .boolean,
                                                          body: .unit))
    check(input: "(\\x:bool->unit.x true) \\y:bool.unit ; (\\x:bool->unit.x true) \\y:bool.unit",
          expect: .application(left: .abstraction(parameter: "_", parameterType: .unit, body: expected),
                                     right: expected))
  }

  func testAs() {
    check(input: "x as bool",
          expect: .right(.application(left: .abstraction(parameter: "x",
                                                                 parameterType: .boolean,
                                                                 body: .variable(name: "x", index: 0)),
                                              right: .variable(name: "x", index: 0))))
  }

  func testAsLambda() {
    let body: Term = .abstraction(parameter: "x", parameterType: .boolean, body: .unit)
    let expected: Term = .application(left: .abstraction(parameter: "x",
                                                         parameterType: .function(parameterType: .boolean, returnType: .unit),
                                                         body: .variable(name: "x", index: 0)),
                                      right: body)
    check(input: "(\\x:bool.unit) as bool->unit", expect: expected)
  }

  func testLetSimple() {
    let t1: Term = .zero
    let t2: Term = .variable(name: "x", index: 0)
    let expected: Term = .letTerm(pattern: .variable(name: "x"), argument: t1, body: t2)
    check(input: "let x = 0 in x", expect: .right(expected))
  }

  func testLet() {
    let t1: Term = .zero
    let t2: Term = .abstraction(parameter: "y",
                                parameterType: .integer,
                                body: .application(left: .variable(name: "y", index: 0),
                                                   right: .variable(name: "x", index: 1)))
    let expected: Term =  .letTerm(pattern: .variable(name: "x"), argument: t1, body: t2)
    check(input: "let x=0 in \\y:int.y x", expect: .right(expected))
  }

  func testLetApp() {
    let t1: Term = .abstraction(parameter: "z",
                                parameterType: .function(parameterType: .boolean, returnType: .integer),
                                body: .application(left: .variable(name: "z", index: 0),
                                                   right: .trueTerm))
    let t2: Term = .application(left: .variable(name: "e", index: 0),
                                right: .abstraction(parameter: "y", parameterType: .boolean, body: .zero))
    let expected: Term = .letTerm(pattern: .variable(name: "e"), argument: t1, body: t2)
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expect: .right(expected))
  }

  func testWildcard() {
    let expected: Term = .application(left: .abstraction(parameter: "_", parameterType: .boolean, body: .unit), right: .trueTerm)
    check(input: "(\\_:bool.unit) true", expect: expected)
  }

  func testAscription() {
    check(input: "0 as int", expect: .application(left: .abstraction(parameter: "x", parameterType: .integer, body: .variable(name: "x", index: 0)), right: .zero))
  }

  func testTuple() {
    check(input: "{0, unit,true}", expect: .tuple(["0":.zero,"1":.unit,"2":.trueTerm]))
  }

  func testEmptyTuple() {
    check(input: "{}", expect: .tuple([:]))
  }

  func testTupleNonValue() {
    let expected: Term = .application(left: .abstraction(parameter: "x", parameterType: .boolean, body: .zero), right: .trueTerm)
    check(input: "{(\\x:bool.0) true}", expect: .tuple(["0":expected]))
  }

  func testTupleProjection() {
    check(input: "{true}.1", expect: .letTerm(pattern: .record(["1":.variable(name: "x")]), argument: .tuple(["0":.trueTerm]), body: .variable(name: "x", index: 0)))
  }

  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expect: .tuple(["0":.zero,"7":.unit,"2":.trueTerm]))
  }

  func testPatternMatching() {
    let expected: Term = .letTerm(pattern: .record(["0":.variable(name: "x"), "1":.variable(name: "y")]), argument: .tuple(["0":.zero, "1":.trueTerm]), body: .variable(name: "x", index: 0))
    check(input: "let {x, y}={0,true} in x", expect: expected)
  }

  func testLetNested() {
    let inner: Term = .application(left: .abstraction(parameter: "z", parameterType: .function(parameterType: .integer, returnType: .integer), body: .variable(name: "z", index: 0)),
                                   right: .abstraction(parameter: "y", parameterType: .integer, body: .variable(name: "y", index: 0)))
    let outer: Term = .application(left: inner, right: .variable(name: "x", index: 0))
    let expected: Term = .letTerm(pattern: .variable(name: "x"), argument: .zero, body: outer)
    check(input: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expect: expected)
  }

  func testProductType() {
    check(input: "\\x:{int, bool}.x", expect: .abstraction(parameter: "x", parameterType: .product(["0":.integer,"1":.boolean]), body: .variable(name: "x", index: 0)))
  }

  func testLetVariablePattern() {
    let inner: Term = .letTerm(pattern: .record(["1":.variable(name: "x")]), argument: .variable(name: "x", index: 0), body: .variable(name: "x", index: 0))
    let outer: Term = .letTerm(pattern: .variable(name: "x"), argument: .tuple(["0":.zero, "1":.trueTerm]), body: inner)
    print(outer)
    check(input: "let x={0,true} in x.1", expect: outer)
  }

  func testVariantTag() {
    check(input: "<a=0> as <a:int>", expect: .tag(label: "a", term: .zero, ascribedType: .sum(["a":.integer])))
  }

  func testVariantTagMultiple() {
    check(input: "<a=0> as <a:int, b:bool>", expect: .tag(label: "a", term: .zero, ascribedType: .sum(["a":.integer, "b":.boolean])))
  }

  func testVariantCase() {
    let expected: Term = .caseTerm(term: .tag(label: "a", term: .zero, ascribedType: .sum(["a":.integer])), cases: ["a":Case(label: "a", parameter: "x", term: .variable(name: "x", index: 0))])
    check(input: "case <a=0> as <a:int> of <a=x> => x", expect:expected)
  }

  func testVariantCases() {
    let cases: [String:Case] = ["a":Case(label: "a", parameter: "x", term: .variable(name: "x", index: 0)),
                         "b":Case(label: "b", parameter: "y", term: .variable(name: "y", index: 0))
                         ]
    let expected: Term = .caseTerm(term: .tag(label: "a", term: .zero, ascribedType: .sum(["a":.integer])), cases: cases)
    check(input: "case <a=0> as <a:int> of <a=x> => x | <b=y> => y", expect:expected)
  }

  func testFix() {
    check(input: "fix \\x:bool.x", expect: .fix(.abstraction(parameter: "x", parameterType: .boolean, body: .variable(name: "x", index: 0))))
  }

  func testLetrec() {
    let t1: Term = .abstraction(parameter: "x", parameterType: .boolean, body: .variable(name: "x", index: 0))
    let argument: Term = .fix(.abstraction(parameter: "x", parameterType: .function(parameterType: .boolean, returnType: .boolean), body: t1))
    let body: Term = .variable(name: "z", index: 0)
    check(input: "letrec z: bool->bool = (\\x:bool.x) in z", expect: .letTerm(pattern: .variable(name: "z"), argument: argument, body: body))
  }

  func testVariableAssignment() {
    let x: Term = .variable(name: "x", index: 1)
    check(input: "x = 0; x", expect: .application(left: .abstraction(parameter: "_", parameterType: .unit, body: x), right: .unit))
  }
  
  func testVariableAssignmentNested() {
    let inner: Term = .application(left: .abstraction(parameter: "_", parameterType: .unit, body: .unit), right: .unit)
    let outer: Term = .application(left: .abstraction(parameter: "_", parameterType: .unit, body: .variable(name: "y", index: 2)), right: inner)
    check(input: "x = 0; y = true; y", expect: outer)
  }

  func testVariableAssignmentNestedOuter() {
    let inner: Term = .application(left: .abstraction(parameter: "_", parameterType: .unit, body: .unit), right: .unit)
    let outer: Term = .application(left: .abstraction(parameter: "_", parameterType: .unit, body: .variable(name: "x", index: 1)), right: inner)
    check(input: "x = 0; y = true; x", expect: outer)
  }
  
}
