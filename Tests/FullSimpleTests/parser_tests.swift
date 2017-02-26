import XCTest
import Parswift
@testable import FullSimple

class ParserTests: XCTestCase {

  /// Tests parsing an abstraction with a parameter with a base type.
  func testAbsBaseType() {
    let expected: Term = .Application(left: .Abstraction(parameter: "x",
                                                         parameterType: .Boolean,
                                                         body: .Variable(name: "x", index: 0)),
                                      right: .Variable(name: "x", index: 0))
    check(input: "(\\x:bool.x) x", expect: expected)
  }

  /// Tests parsing an application with differing amounts of whitespace.
  func testAppSpaces() {
    let expected: Term = .Application(left: .Variable(name: "a", index: 0),
                                      right: .Variable(name: "b", index: 1))
    
    check(input: "a b", expect: .right(expected))
    check(input: "a  b", expect: .right(expected))
    check(input: "a     b", expect: .right(expected))
    check(input: "a     b;", expect: .right(expected))
    check(input: "ab", expect: .right(.Variable(name: "ab", index: 0)))
  }

  /// Tests parsing succ terms.
  func testSucc() {
    let expected: Term = .Succ(.Pred(.Zero))
    check(input: "succ(pred 0)", expect: expected)
    check(input: "succ pred 0", expect: expected)
  }

  /// Tests parsing pred terms.
  func testPred() {
    let expected: Term = .Pred(.Succ(.Zero))
    check(input: "pred(succ 0)", expect: expected)
  }

  /// Tests parsing an abstraction with a complex parameter type.
  func testAbsArrowType() {
    let expected: Term = .Abstraction(parameter: "x",
                                      parameterType: .Function(parameterType: .Integer,
                                                               returnType: .Boolean),
                                      body: .Variable(name: "x", index: 0))
    check(input: "\\x:int->bool.x", expect: expected)
  }

  /// Tests parsing an if-else statement without any parentheses.
  func testIfElseNoParens() {
    let expected: Term = .If(condition: .Succ(.Pred(.Zero)), trueBranch: .False, falseBranch: .True)
    check(input: "if succ pred 0 then false else true", expect: expected)
  }

  /// Tests parsing an if-else statement with an application in the conditional. 
  func testIfElseApplicationConditional() {
    let condition: Term = .Application(left: .Abstraction(parameter: "x",
                                                          parameterType: .Boolean,
                                                          body: .Variable(name: "x", index: 0)),
                                       right: .True)
    let expected: Term = .If(condition: condition, trueBranch: .False, falseBranch: .True)
    check(input: "if (\\x:bool.x) true then false else true", expect: expected)
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
          expect: .right(expected))
  }

  func testAppInSucc() {
    let expected: Term = .Succ(.Succ(.Abstraction(parameter: "x",
                                                  parameterType: .Function(parameterType: .Boolean, returnType: .Integer),
                                                  body: .Application(left: .Variable(name: "x", index: 0),
                                                                     right: .Zero))))
    check(input: "(succ (succ (\\x:bool->int.x 0)))", expect: expected)
  }

  func testIfIsZero() {
    let expected: Term = .If(condition: .IsZero(.Zero), trueBranch: .False, falseBranch: .True)
    check(input: "if (isZero 0) then false else true", expect: expected)
  }

  func testAppTermInIfClause() {
    let expected: Term = .If(condition: .True,
                             trueBranch: .Application(left: .Abstraction(parameter: "x",
                                                                         parameterType: .Boolean,
                                                                         body: .Variable(name: "x", index: 0)),
                                                      right: .True),
                             falseBranch: .Succ(.Zero))
    check(input: "if true then (\\x:bool.x) true else succ 0", expect: expected)
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
    check(input: "(\\x:bool.(\\y:bool->unit.y x)) true \\z:bool.unit", expect: expected)
  }


  func testNestedFunctionApplication() {
    let body: Term = .Application(left: .Variable(name: "f", index: 1), right: .Application(left: .Variable(name: "f", index: 1), right: .Variable(name: "x", index: 0)))
    let innerTerm: Term = .Abstraction(parameter: "x", parameterType: .Integer, body: body)
    let outerTerm: Term = .Abstraction(parameter: "f", parameterType: .Function(parameterType: .Integer, returnType: .Integer), body: innerTerm)
    check(input: "\\f:int->int.\\x:int.f (f x)", expect: outerTerm)
  }

  func testLambdaBaseType() {
    check(input: "\\x:A.x",
          expect: .Abstraction(parameter: "x",
                                     parameterType: .Base(typeName: "A"),
                                     body: .Variable(name: "x", index: 0)))
  }

  // MARK - Extension Tests

  func testSequenceUnit() {
    let t1: Term = .Unit
    let t2: Term = .Unit
    check(input:"unit;unit", expect: .Application(left: .Abstraction(parameter: "_",
                                                                           parameterType: .Unit,
                                                                           body: t2),
                                                        right: t1))
  }

  func testSequenceApp() {
    let t1: Term = .Application(left: .Variable(name: "a", index: 0),
                                right: .Variable(name: "b", index: 1))
    // c is at index 3 instead of 2 due to the _ parameter that is used in the sequence's derived form.
    let t2: Term = .Application(left: .Variable(name: "c", index: 3),
                                right: .Variable(name: "d", index: 4))
    let expected: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: t2),
                                      right: t1)
    check(input: "a b; c d", expect: .right(expected))
    check(input: "a b ;c d", expect: .right(expected))
    check(input: "a b; c d", expect: .right(expected))
    check(input: "a b ; c d", expect: .right(expected))
  }

  func testBaseType() {
    let expected: Term = .Abstraction(parameter: "x",
                                      parameterType: .Base(typeName: "A"),
                                      body: .Variable(name: "x", index: 0))
    check(input: "\\x:A.x", expect: expected)
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
          expect: .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: expected),
                                     right: expected))
  }

  func testAs() {
    check(input: "x as bool",
          expect: .right(.Application(left: .Abstraction(parameter: "x",
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
    check(input: "(\\x:bool.unit) as bool->unit", expect: expected)
  }

  func testLetSimple() {
    let t1: Term = .Zero
    let t2: Term = .Variable(name: "x", index: 0)
    let expected: Term = .Let(pattern: .Variable(name: "x"), argument: t1, body: t2)
    check(input: "let x = 0 in x", expect: .right(expected))
  }

  func testLet() {
    let t1: Term = .Zero
    let t2: Term = .Abstraction(parameter: "y",
                                parameterType: .Integer,
                                body: .Application(left: .Variable(name: "y", index: 0),
                                                   right: .Variable(name: "x", index: 1)))
    let expected: Term =  .Let(pattern: .Variable(name: "x"), argument: t1, body: t2)
    check(input: "let x=0 in \\y:int.y x", expect: .right(expected))
  }

  func testLetApp() {
    let t1: Term = .Abstraction(parameter: "z",
                                parameterType: .Function(parameterType: .Boolean, returnType: .Integer),
                                body: .Application(left: .Variable(name: "z", index: 0),
                                                   right: .True))
    let t2: Term = .Application(left: .Variable(name: "e", index: 0),
                                right: .Abstraction(parameter: "y", parameterType: .Boolean, body: .Zero))
    let expected: Term = .Let(pattern: .Variable(name: "e"), argument: t1, body: t2)
    check(input: "let e=\\z:bool->int.(z true) in e \\y:bool.0", expect: .right(expected))
  }

  func testWildcard() {
    let expected: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Boolean, body: .Unit), right: .True)
    check(input: "(\\_:bool.unit) true", expect: expected)
  }

  func testAscription() {
    check(input: "0 as int", expect: .Application(left: .Abstraction(parameter: "x", parameterType: .Integer, body: .Variable(name: "x", index: 0)), right: .Zero))
  }

  func testTuple() {
    check(input: "{0, unit,true}", expect: .Tuple(["0":.Zero,"1":.Unit,"2":.True]))
  }

  func testEmptyTuple() {
    check(input: "{}", expect: .Tuple([:]))
  }

  func testTupleNonValue() {
    let expected: Term = .Application(left: .Abstraction(parameter: "x", parameterType: .Boolean, body: .Zero), right: .True)
    check(input: "{(\\x:bool.0) true}", expect: .Tuple(["0":expected]))
  }

  func testTupleProjection() {
    check(input: "{true}.1", expect: .Let(pattern: .Record(["1":.Variable(name: "x")]), argument: .Tuple(["0":.True]), body: .Variable(name: "x", index: 0)))
  }

  func testLabeledTuple() {
    check(input: "{0, 7:unit,true}", expect: .Tuple(["0":.Zero,"7":.Unit,"2":.True]))
  }

  func testPatternMatching() {
    let expected: Term = .Let(pattern: .Record(["0":.Variable(name: "x"), "1":.Variable(name: "y")]), argument: .Tuple(["0":.Zero, "1":.True]), body: .Variable(name: "x", index: 0))
    check(input: "let {x, y}={0,true} in x", expect: expected)
  }

  func testLetNested() {
    let inner: Term = .Application(left: .Abstraction(parameter: "z", parameterType: .Function(parameterType: .Integer, returnType: .Integer), body: .Variable(name: "z", index: 0)),
                                   right: .Abstraction(parameter: "y", parameterType: .Integer, body: .Variable(name: "y", index: 0)))
    let outer: Term = .Application(left: inner, right: .Variable(name: "x", index: 0))
    let expected: Term = .Let(pattern: .Variable(name: "x"), argument: .Zero, body: outer)
    check(input: "let x=0 in (\\z:int->int.z) (\\y:int.y) x", expect: expected)
  }

  func testProductType() {
    check(input: "\\x:{int, bool}.x", expect: .Abstraction(parameter: "x", parameterType: .Product(["0":.Integer,"1":.Boolean]), body: .Variable(name: "x", index: 0)))
  }

  func testLetVariablePattern() {
    let inner: Term = .Let(pattern: .Record(["1":.Variable(name: "x")]), argument: .Variable(name: "x", index: 0), body: .Variable(name: "x", index: 0))
    let outer: Term = .Let(pattern: .Variable(name: "x"), argument: .Tuple(["0":.Zero, "1":.True]), body: inner)
    print(outer)
    check(input: "let x={0,true} in x.1", expect: outer)
  }

  func testVariantTag() {
    check(input: "<a=0> as <a:int>", expect: .Tag(label: "a", term: .Zero, ascribedType: .Sum(["a":.Integer])))
  }

  func testVariantTagMultiple() {
    check(input: "<a=0> as <a:int, b:bool>", expect: .Tag(label: "a", term: .Zero, ascribedType: .Sum(["a":.Integer, "b":.Boolean])))
  }

  func testVariantCase() {
    let expected: Term = .Case(term: .Tag(label: "a", term: .Zero, ascribedType: .Sum(["a":.Integer])), cases: ["a":Case(label: "a", parameter: "x", term: .Variable(name: "x", index: 0))])
    check(input: "case <a=0> as <a:int> of <a=x> => x", expect:expected)
  }

  func testVariantCases() {
    let cases: [String:Case] = ["a":Case(label: "a", parameter: "x", term: .Variable(name: "x", index: 0)),
                         "b":Case(label: "b", parameter: "y", term: .Variable(name: "y", index: 0))
                         ]
    let expected: Term = .Case(term: .Tag(label: "a", term: .Zero, ascribedType: .Sum(["a":.Integer])), cases: cases)
    check(input: "case <a=0> as <a:int> of <a=x> => x | <b=y> => y", expect:expected)
  }

  func testFix() {
    check(input: "fix \\x:bool.x", expect: .Fix(.Abstraction(parameter: "x", parameterType: .Boolean, body: .Variable(name: "x", index: 0))))
  }

  func testLetrec() {
    let t1: Term = .Abstraction(parameter: "x", parameterType: .Boolean, body: .Variable(name: "x", index: 0))
    let argument: Term = .Fix(.Abstraction(parameter: "x", parameterType: .Function(parameterType: .Boolean, returnType: .Boolean), body: t1))
    let body: Term = .Variable(name: "z", index: 0)
    check(input: "letrec z: bool->bool = (\\x:bool.x) in z", expect: .Let(pattern: .Variable(name: "z"), argument: argument, body: body))
  }

  func testVariableAssignment() {
    let x: Term = .Variable(name: "x", index: 1)
    check(input: "x = 0; x", expect: .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: x), right: .Unit))
  }
  
  func testVariableAssignmentNested() {
    let inner: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: .Unit), right: .Unit)
    let outer: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: .Variable(name: "y", index: 2)), right: inner)
    check(input: "x = 0; y = true; y", expect: outer)
  }

  func testVariableAssignmentNestedOuter() {
    let inner: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: .Unit), right: .Unit)
    let outer: Term = .Application(left: .Abstraction(parameter: "_", parameterType: .Unit, body: .Variable(name: "x", index: 1)), right: inner)
    check(input: "x = 0; y = true; x", expect: outer)
  }
  
}
