//
//  TestHelpers.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import XCTest

func assertParseResult<A, T: Equatable>(_ str: String, _ t: T, _ parser: (String) -> Result<(A,T), ParseError>) {
  switch parser(str) {
  case let .success(result):
    XCTAssertEqual(t, result.1)
    break
  case .failure(_):
    XCTAssertTrue(false)
    break
  }
}

func parseAndEvaluateLines(_ lines: [String], parser: (String) -> Result<((), UATerm), ParseError>, evaluator: (UATerm) -> UATerm) {
    let testCases = lines.flatMap { (line: String) -> (String, String)? in
      let splitLine = line.components(separatedBy: ";")
      if splitLine.count == 2 {
        return (splitLine[0] , splitLine[1])
      }
      return nil
    }
    testCases.forEach {
      switch (parser($0.0), parser($0.1)) {
        case let (.success(firstUATerms), .success(secondUATerms)):
          XCTAssertEqual(secondUATerms.1, evaluator(firstUATerms.1))
        break
        default:
        XCTAssertTrue(false)
        break
      }
    }
}
