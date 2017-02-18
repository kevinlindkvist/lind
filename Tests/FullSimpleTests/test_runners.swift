import Foundation
import XCTest
import Parswift
@testable import FullSimple

/// Parses `input` and asserts that the resulting term is equal to
/// `term`.
func check(input: String, expect term: Term, file: StaticString = #file, line: UInt = #line) {
  check(input: input, expect: .right(term), file: file, line: line)
}

/// Parses `input` and asserts that the result is equal to `parseResult`.
func check(input: String,
           expect expectedResult: Either<ParseError, Term>,
           file: StaticString = #file,
           line: UInt = #line) {
  let result = parse(input: input, context: ParseContext())
  switch (result, expectedResult) {
  case let (.right(t1, _), .right(t2)):
    XCTAssertEqual(t1, t2, "Expected \(t1) to be \(t2).", file: file, line: line)
  case (.left, .left):
    break
  case let (.left(error), .right(term)):
    XCTFail("Expected to parse \(term) from \(input), but got \(error)", file: file, line: line)
  case let (.right(term), .left):
    XCTFail("Expected parsing \(input) to fail, but got \(term).", file: file, line: line)
  }
}

/// Parses `input`, evaluates it, and asserts that the result is equal to `expectedTerm`.
func check(input: String,
           expectEvaluated expectedTerm: Term,
           file: StaticString = #file,
           line: UInt = #line) {
  let result = parse(input: input, context: ParseContext())
  switch (result) {
  case let .right(parsedTerm, context):
    let evaluatedTerm = evaluate(term: parsedTerm, namedTerms: context.namedTerms)
    XCTAssertEqual(evaluatedTerm,
                   expectedTerm,
                   "Expected \(evaluatedTerm) to be \(expectedTerm).",
                   file: file,
                   line: line)
  case let .left(error):
    XCTFail("Could not parse \(input) due to \(error).", file: file, line: line)
  }
}

/// Parses `input` and asserts that the parsed term's type is `expectedType` when checked with the
/// provided `contextTypes` in the context.
func check(input: String,
           expect expectedType: Type,
           with contextTypes: TypeContext = [:],
           file: StaticString = #file,
           line: UInt = #line) {
  check(input: input, expect: .right((ParseContext(), expectedType)), with: contextTypes, file: file, line: line)
}

/// Parses `input` and asserts that the type result is `expectedResult` when checked with the
/// provided `contextTypes` in the context.
func check(input: String,
           expect expectedResult: TypeResult,
           with contextTypes: TypeContext = [:],
           file: StaticString = #file,
           line: UInt = #line) {
  switch parse(input: input, context: ParseContext(types: contextTypes)) {
  case let .right(term, parseContext):
    switch (typeOf(term: term, parsedContext: parseContext), expectedResult) {
    case let (.right(_, parsedType), .right(_, expectedType)):
      XCTAssertEqual(expectedType,
                     parsedType, "Expected \(parsedType) to be \(expectedType).",
                     file: file,
                     line: line)
    case let (.left(error), .right(_, expectedType)):
      XCTFail("Expected type of \(term) to be \(expectedType), but failed with \(error).",
      file: file,
      line: line)
    case (.left, .left):
      break
    case let(.right(_, parsedType), .left):
      XCTFail("Expected type of \(term) to be fail, but got \(parsedType).",
      file: file,
      line: line)
    }
  case let .left(error):
    XCTFail("Could not parse \(input) due to \(error).", file: file, line: line)
  }
}

/// Returns a default parse error, useful for expecting failures of parsing and type checking.
func parseError() -> ParseError {
  return ParseError(position: SourcePosition(name: "", line: 1, column: 1), messages: [])
}
