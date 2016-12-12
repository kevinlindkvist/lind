//
//  LindTypeChecking.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation

public func typeOf(term: Term, context: TypeContext) -> TypeResult {
  switch term {
    case let .variable(_, index: idx):
      return typeOf(variable: idx, context: context)
    case let .abstraction(_, type, term):
      return typeOf(abstraction: term, type: type, context: context)
    case let .application(left, right):
      return typeOf(application: (left, right), context: context)
    case .tmTrue:
      return .success(context, .boolean)
    case .tmFalse:
      return .success(context, .boolean)
    case let .ifElse(conditional, trueBranch, falseBranch):
      return typeOf(ifElse: (conditional, trueBranch, falseBranch), context: context)
    case .zero:
      return .success(context, .integer)
    case let .isZero(term):
      return typeOf(isZero: term, context: context)
    case let .succ(term):
      return typeOf(predOrSucc: term, context: context)
    case let .pred(term):
      return typeOf(predOrSucc: term, context: context)
    case .unit:
      return .success(context, .unit)
  }
}

private func typeOf(variable: Int, context: TypeContext) -> TypeResult {
  if let type = context[variable] {
    return .success(context, type)
  } else {
    return .failure(.message("Could not find \(variable) in \(context)"))
  }
}

private func typeOf(abstraction: Term, type: Type, context: TypeContext) -> TypeResult {
    var shiftedContext = context
    context.forEach { k, v in
      shiftedContext[k+1] = v
    }
    let bodyType = typeOf(term: abstraction, context: union([0:type],shiftedContext))
    switch bodyType {
      case let .success(_, returnType):
        return .success(context, .function(argumentType: type, returnType: returnType))
      case let .failure(error):
        return .failure(error)
    }
}

private func typeOf(application: (left: Term, right: Term), context: TypeContext) -> TypeResult {
  let leftType = typeOf(term: application.left, context: context)
  let rightType = typeOf(term: application.right, context: context)
  switch (leftType, rightType) {
    case let (.success(_, .function(parameterType, returnType)), .success(_, argumentType)) where parameterType == argumentType:
      return .success(context, returnType)
    default:
      return .failure(.message("Incorrect application, left was: \(application.left) and right was: \(application.right)."))
  }
}

private func typeOf(isZero: Term, context: TypeContext) -> TypeResult {
  let result = typeOf(term: isZero, context: context)
  switch result {
    case let .success(_, type) where type == .integer:
      return .success(context, .boolean)
    default:
      return .failure(.message("isZero called on non-integer argument \(result)"))
  }
}

private func typeOf(predOrSucc: Term, context: TypeContext) -> TypeResult {
  let result = typeOf(term: predOrSucc, context: context)
  switch result {
    case let .success(_, type) where type == .integer:
      return .success(context, .integer)
    default:
      return .failure(.message("pred/succ called on non-integer term: \(result)"))
  }
}

private func typeOf(ifElse: (conditional: Term, trueBranch: Term, falseBranch: Term), context: TypeContext) -> TypeResult {
  let conditionalResult = typeOf(term: ifElse.conditional, context: context)
  let trueBranch = typeOf(term: ifElse.trueBranch, context: context)
  let falseBranch = typeOf(term: ifElse.falseBranch, context: context)
  switch conditionalResult {
    case let .success(_, type) where type == .boolean:
      switch (trueBranch, falseBranch) {
        case let (.success(_, t1), .success(_, t2)) where t1 == t2:
          return .success(context, t1)
        default:
          return .failure(.message("Type of if branches don't match: \(trueBranch),\(falseBranch)"))
      }
    case let .success(_, type):
      return .failure(.message("Incorrect type of conditional: \(type)"))
    case let .failure(message):
      return .failure(message)
  }
}
