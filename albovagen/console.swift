//
//  ConsoleIO.swift
//  lind
//
//  Created by Kevin Lindkvist on 11/23/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

enum OutputType {
  case error
  case standard
}

func write(line: String, to: OutputType = .standard) {
  write(message: line, to: to)
}

func write(string: String, to: OutputType = .standard) {
  write(message: string, to: to, terminator: "")
}

fileprivate func write(message: String, to: OutputType, terminator: String = "\n") {
  switch to {
  case .standard:
    // Write messages in the default color.
    print("\(message)", terminator: terminator)
  case .error:
    // Write the error message in red.
    fputs("\(message)\n", stderr)
  }
}

func read() -> String {
  let handle = FileHandle.standardInput
  let data = handle.availableData
  let text = String(data: data, encoding: String.Encoding.utf8) ?? ""
  return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
}
