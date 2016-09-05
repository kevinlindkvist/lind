//
//  Reply.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

public enum Reply<Input, Context, Output> {
  case failure((Input, Context), [String], String)
  case done(Input, Context, Output)
}

extension Reply {
  var result: Result<(Context, Output), ParseError> {
      switch self {
      case let .failure(_, o, m):
        return .failure(.message("Failed to read message \(o) \n\(m)"))
      case let .done(_, context, output):
        return .success(context, output)
    }
  }
}
