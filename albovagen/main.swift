//
//  main.swift
//  albovagen
//
//  Created by Kevin Lindkvist on 11/23/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import lind

write(line: "Welcome to lind, type 'q' to quit.\n")
write(string: "λ: ")

func run(input: String, namingContext: NamingContext = [:], typeContext: TypeContext = [:]) {
  if (input == "q") {
   return;
  }

  let result = evaluate(input: input)

  write(line: " -> " + description(evaluation: result))
  write(string: "λ: ")

  run(input: read())
}

run(input: read())

