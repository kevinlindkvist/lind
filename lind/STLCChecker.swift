//
//  STLCChecker.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

public func typeOf(t: STLCTerm, context: TypeContext) -> Result<(TypeContext, STLCType), TypeError> {
  return .success(context, .nat)
}
