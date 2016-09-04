//
//  LCSimpleTypes.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

typealias TypeContext = [Int:STLCType]

indirect enum STLCType {
  case T_T(STLCType, STLCType)
  case Bool
  case Nat
}

enum STLCTerm {
  case ULCTerm
  case UATerm
}