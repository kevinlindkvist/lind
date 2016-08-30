//
//  TestHelpers.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/29/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result
import XCTest

func parseAndEvaluateLines(lines: [String], parser: String -> Result<[Term], ParseError>, evaluator: [Term] -> [Term]) {
    let testCases = lines.flatMap { (line: String) -> (String, String)? in
      let splitLine = line.componentsSeparatedByString(";")
      if splitLine.count == 2 {
        return (splitLine[0] , splitLine[1])
      }
      return nil
    }
    testCases.forEach {
      switch (parser($0.0), parser($0.1)) {
        case let (.Success(firstTerms), .Success(secondTerms)):
          XCTAssertEqual(secondTerms, evaluator(firstTerms))
        break
        default:
        XCTAssertTrue(false)
        break
      }
    }
}
