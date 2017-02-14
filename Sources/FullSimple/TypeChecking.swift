//
//  LindTypeChecking.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import Parser

public func typeOf(term: Term, context: TypeContext) -> TypeResult {
  switch term {
  case let .Variable(name, _):
    return typeOf(variable: name, context: context)
  case let .Abstraction(parameter, type, term):
    return typeOf(parameter: parameter, body: term, type: type, context: context)
  case let .Application(left, right):
    return typeOf(application: (left, right), context: context)
  case .True:
    return .success(context, .Boolean)
  case .False:
    return .success(context, .Boolean)
  case let .If(conditional, trueBranch, falseBranch):
    return typeOf(ifElse: (conditional, trueBranch, falseBranch), context: context)
  case .Zero:
    return .success(context, .Integer)
  case let .IsZero(term):
    return typeOf(isZero: term, context: context)
  case let .Succ(term):
    return typeOf(predOrSucc: term, context: context)
  case let .Pred(term):
    return typeOf(predOrSucc: term, context: context)
  case .Unit:
    return .success(context, .Unit)
  case let .Tuple(contents):
    var types: [String:Type] = [:]
    var encounteredError = false
    contents.forEach { (key, value) in
      switch typeOf(term: value, context: context) {
      case let .success(type):
        types[key] = type.1
        break
      case .failure:
        encounteredError = true
        break
      }
    }

    if encounteredError {
      return .failure(.message("Tuple contents has incorrect type."))
    } else {
      return .success(context, .Product(types))
    }
  case let .Let(pattern, argument, body):
    switch typeOf(term: argument, context: context) {
    case let .success(_, type):
      if let patternContext = typeOf(pattern: pattern, argument: type, context: context) {
        return typeOf(term: body, context: union(context, patternContext))
      } else {
        return .failure(.message("Haven't implemented pattern types."))
      }
    default:
      return .failure(.message("Couldn't typecheck pattern argument \(argument)"))
    }
  case let .Tag(label, t, ascribedType):
    switch (typeOf(term: t, context: context), ascribedType) {
    case let (.success(_, type), .Sum(labeledTypes)) where type == labeledTypes[label]:
      return .success(context, ascribedType)
    default:
      return .failure(.message("Couldn't typecheck tag."))
    }
  case let .Case(t, cases):
    switch typeOf(term: t, context: context) {
    case let .success(_, .Sum(sumTypes)):
      let deducedTypes = sumTypes.flatMap { (label, labeledType) -> (String, Type)? in
        if let variantCase = cases[label] {
          switch typeOf(term: variantCase.term, context: union(context, [variantCase.parameter:labeledType])) {
          case let .success(_, deducedType):
            return (label, deducedType)
          default:
            return nil
          }
        } else {
          return nil
        }
      }

      let filteredTypes = deducedTypes.filter { label, deducedType in
        deducedType != deducedTypes.first!.1
      }
      
      if filteredTypes.isEmpty {
        return .success(context, deducedTypes.first!.1)
      } else {
        return .failure(.message("Couldn't typecheck case, cases that didn't match: \(deducedTypes)."))
      }
    default:
      return .failure(.message("Couldn't typecheck case."))
    }
  }
}

private func typeOf(pattern: Pattern, argument: Type, context: TypeContext) -> TypeContext? {
  switch (pattern, argument) {
  case let (.Variable(name), type):
    return [name: type]
  case let (.Record(contents), .Product(types)):
    var updatedContext: TypeContext = [:]
    var encounteredError: Bool = false
    contents.forEach { key, value in
      if let type = types[key], let subcontext = typeOf(pattern: value, argument: type, context: context) {
        subcontext.forEach { k, v in
          updatedContext[k] = v
        }
      } else {
        encounteredError = true
      }
    }
    return encounteredError ? nil : updatedContext
  default:
    return nil
  }
}

private func typeOf(variable: String, context: TypeContext) -> TypeResult {
  if let type = context[variable] {
    return .success(context, type)
  } else {
    return .failure(.message("Could not find \(variable) in \(context)"))
  }
}

private func typeOf(parameter: String, body: Term, type: Type, context: TypeContext) -> TypeResult {
  var shiftedContext = context
  shiftedContext[parameter] = type
  let bodyType = typeOf(term: body, context: shiftedContext)
  switch bodyType {
  case let .success(_, returnType):
    return .success(context, .Function(parameterType: type, returnType: returnType))
  case let .failure(error):
    return .failure(error)
  }
}

private func typeOf(application: (left: Term, right: Term), context: TypeContext) -> TypeResult {
  let leftType = typeOf(term: application.left, context: context)
  let rightType = typeOf(term: application.right, context: context)
  switch (leftType, rightType) {
  case let (.success(_, .Function(parameterType, returnType)), .success(_, argumentType)) where parameterType == argumentType:
    return .success(context, returnType)
  case let (.success(_, .Function(parameterType, returnType)), .success(_, argumentType)):
    return .failure(.message("Incorrect application types, function: \(parameterType, returnType), argument: \(argumentType)"))
  case let (.success(c1, t1), .success(c2, t2)):
    return .failure(.message("Incorrect application\n\(application.left) :: \(t1) - \(c1) \n\(application.right) :: \(t2) - \(c2)"))
  case let (.success, .failure(error)):
    return .failure(.message("Could not parse type of \(application.right)\n\(error)"))
  case let (.failure(error), .success):
    return .failure(.message("Could not parse type of \(application.left)\n\(error)"))
  case (.failure, .failure):
    return .failure(.message("Could not parse type of \(application.left) or \(application.right)"))
  default:
    return .failure(.message("Unknown error: \(application)"))
  }
}

private func typeOf(isZero: Term, context: TypeContext) -> TypeResult {
  let result = typeOf(term: isZero, context: context)
  switch result {
  case let .success(_, type) where type == .Integer:
    return .success(context, .Boolean)
  default:
    return .failure(.message("isZero called on non-integer argument \(result)"))
  }
}

private func typeOf(predOrSucc: Term, context: TypeContext) -> TypeResult {
  let result = typeOf(term: predOrSucc, context: context)
  switch result {
  case let .success(_, type) where type == .Integer:
    return .success(context, .Integer)
  default:
    return .failure(.message("pred/succ called on non-integer term: \(result)"))
  }
}

private func typeOf(ifElse: (conditional: Term, trueBranch: Term, falseBranch: Term), context: TypeContext) -> TypeResult {
  let conditionalResult = typeOf(term: ifElse.conditional, context: context)
  let trueBranch = typeOf(term: ifElse.trueBranch, context: context)
  let falseBranch = typeOf(term: ifElse.falseBranch, context: context)
  switch conditionalResult {
  case let .success(_, type) where type == .Boolean:
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
