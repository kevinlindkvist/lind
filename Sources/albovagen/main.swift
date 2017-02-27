//
//  main.swift
//  albovagen
//
//  Created by Kevin Lindkvist on 11/23/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import FullSimple

write(line: "Welcome to lind, type '.q' to quit, or '.c' to show the current context.\n")
write(string: "λ: ")

func run(input: String, context: ParseContext) {
  if (input == ".q") {
   return;
  } else if (input == ".c") {
    write(line: "\(context)")
    write(string: "λ: ")
    run(input: read(), context: context)
  } else {
    let result = evaluate(input: input, context: context)

    write(line: "  " + description(evaluation: result))
    write(string: "λ: ")

    switch result {
    case .left:
      run(input: read(), context: context)
    case let .right(_, _, updatedContext):
      run(input: read(), context: updatedContext)
    }
  }
}

run(input: read(), context: ParseContext(terms: [:], types: [:], namedTypes: [:], namedTerms: []))

