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

indirect enum STLCTerm {
  case tmTrue
  case tmFalse
  case ifElse(STLCTerm, STLCTerm, STLCTerm)
  case zero
  case succ(STLCTerm)
  case pred(STLCTerm)
  case isZero(STLCTerm)
  case va(String, Int)
  case abs(String, STLCTerm)
  case app(STLCTerm, STLCTerm)
}