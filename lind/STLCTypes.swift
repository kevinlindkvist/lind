//
//  LCSimpleTypes.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

typealias TypeContext = [Int:STLCType]

indirect enum STLCType {
  case t_T(STLCType, STLCType)
  case bool
  case nat
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
