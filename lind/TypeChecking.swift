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
    case let .Variable(_, index: idx):
      return typeOf(variable: idx, context: context)
    case let .Abstraction(_, type, term):
      return typeOf(abstraction: term, type: type, context: context)
    case let .Application(left, right):
      return typeOf(application: (left, right), context: context)
    case .True:
      return .success(context, .boolean)
    case .False:
      return .success(context, .boolean)
    case let .If(conditional, trueBranch, falseBranch):
      return typeOf(ifElse: (conditional, trueBranch, falseBranch), context: context)
    case .Zero:
      return .success(context, .integer)
    case let .IsZero(term):
      return typeOf(isZero: term, context: context)
    case let .Succ(term):
      return typeOf(predOrSucc: term, context: context)
    case let .Pred(term):
      return typeOf(predOrSucc: term, context: context)
    case .Unit:
      return .success(context, .Unit)
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
    case let (.success(_, .function(parameterType, returnType)), .success(_, argumentType)):
      return .failure(.message("Incorrect application types, function: \(parameterType, returnType), argument: \(argumentType)"))
    default:
      return .failure(.message("Incorrect application, left was: \(leftType) and right was: \(rightType)."))
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
