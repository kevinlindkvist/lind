//
//  Reply.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

public enum Reply<Input, Context, Output> {
  case Failure((Input, Context), [String], String)
  case Done(Input, Context, Output)
}

extension Reply {
  var result: Result<(Context, Output), ParseError> {
      switch self {
      case let .Failure(_, o, m):
        return .Failure(.Message("Failed to read message \(o) \n\(m)"))
      case let .Done(_, context, output):
        return .Success(context, output)
    }
  }
}