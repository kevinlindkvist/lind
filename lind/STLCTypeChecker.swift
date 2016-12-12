//
//  STLCChecker.swift
//  lind
//
//  Created by Kevin Lindkvist on 9/4/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

func typeOf(t: STLCTerm, context: [Int:STLCType]) -> STLCType? {
  switch t {
  case let .va(_, idx):
    if let type = context[idx] {
      return type
    } else {
      print("Could not find \(idx) in \(context)")
      return nil
    }
  case let .abs(_, type, term):
    var shiftedContext = context
    context.forEach { k, v in
      shiftedContext[k+1] = v
    }
    if let t2 = typeOf(t: term, context: union(shiftedContext, [0:type])) {
      return .t_t(type, t2)
    } else {
      return nil
    }
  case let .app(t1, t2):
    if let tyT1 = typeOf(t: t1, context: context),
      let tyT2 = typeOf(t: t2, context: context) {
      switch tyT1 {
        case let .t_t(tyT11, tyT22) where tyT11 == tyT2: return tyT22
        case let .t_t(tyT11, _):
          print("App types inconsistent expected:(\(tyT11)) got:(\(tyT2))")
          return nil
        default:  
          print("Incorrect type of App:(\(tyT1)) term: \(t)")
          return nil
      }
    } else {
      return nil
    }
  case .tmTrue: return .bool
  case .tmFalse: return .bool
  case let .ifElse(conditional, trueBranch, falseBranch):
    if typeOf(t: conditional, context: context) == .bool {
      let tyTrue = typeOf(t: trueBranch, context: context)
      let tyFalse = typeOf(t: falseBranch, context: context)
      if tyTrue == tyFalse {
        return tyTrue
      } else {
        print("type of if branches not equal \(tyTrue) \(tyFalse)")
        return nil
      }
    } else {
      print("type of if conditional not bool: \(conditional)")
      return nil
    }
  case .zero: return .int
  case let .isZero(term):
    let type = typeOf(t: term, context: context)
    if type == .int {
      return .bool
    } else {
      print("isZero called with non-nat argument")
      return nil
    }
  case let .succ(term):
    let type = typeOf(t: term, context: context)
    if type == .int {
      return .int
    } else {
      print("succ called with non-nat argument")
      return nil
    }
  case let .pred(term):
    let type = typeOf(t: term, context: context)
    if type == .int {
      return .int
    } else {
      print("pred called with non-nat argument")
      return nil
    }
  // Extensions
  case .unit: return .unit

  }
}
