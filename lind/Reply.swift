//
//  Reply.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

public enum Reply<Input, Output> {
  case Failure(Input, [String], String)
  case Done(Input, Output)
}

extension Reply {
  var result: Result<Output, ParseError> {
      switch self {
      case let .Failure(_, o, m):
        return .Failure(.Message("Failed to read message \(o) \n\(m)"))
      case let .Done(_, output):
        return .Success(output)
    }
  }
}