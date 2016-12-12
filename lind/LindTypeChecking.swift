//
//  LindTypeChecking.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public func typeOf(term: Term, context: TypeContext) -> TypeResult {
  return .success(context, .integer)
}
