//
//  LindTypeChecking.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import Parser

private func add(type: Type, to context: TypeContext) -> TypeContext {
  var shiftedContext: TypeContext = [:]
  context.forEach { key, value in
    shiftedContext[key+1] = value
  }
  shiftedContext[0] = type
  return shiftedContext
}

private func add(pattern: [Int:Type], to context: TypeContext) -> TypeContext {
  var shiftedContext: TypeContext = [:]
  context.forEach { key, value in
    shiftedContext[key+pattern.count] = value
  }
  pattern.forEach { key, value in
    shiftedContext[key] = value
  }
  return shiftedContext
}

public func typeOf(term: Term, context: ParseContext) -> TypeResult {
  var types = context.types
  for (index, namedTerm) in context.namedTerms.enumerated() {
    switch typeOf(term: namedTerm, context: types) {
    case let .right(type):
      types[index] = type.1
    case let .left(error):
      return .left(error)
    }
  }
  return typeOf(term: term, context: types)
}

private func typeOf(term: Term, context: TypeContext) -> TypeResult {
  switch term {
  case let .Variable(_, index):
    return typeOf(variable: index, context: context)
  case let .Abstraction(parameter, type, term):
    return typeOf(parameter: parameter, body: term, type: type, context: context)
  case let .Application(left, right):
    return typeOf(application: (left, right), context: context)
  case .True:
    return .right(context, .Boolean)
  case .False:
    return .right(context, .Boolean)
  case let .If(conditional, trueBranch, falseBranch):
    return typeOf(ifElse: (conditional, trueBranch, falseBranch), context: context)
  case .Zero:
    return .right(context, .Integer)
  case let .IsZero(term):
    return typeOf(isZero: term, context: context)
  case let .Succ(term):
    return typeOf(predOrSucc: term, context: context)
  case let .Pred(term):
    return typeOf(predOrSucc: term, context: context)
  case .Unit:
    return .right(context, .Unit)
  case let .Tuple(contents):
    return typeOf(tuple: contents, context: context)
  case let .Let(pattern, argument, body):
    return typeOf(letTerm: pattern, argument: argument, body: body, context: context)
  case let .Tag(label, t, ascribedType):
    return typeOf(tag: label, term: t, ascribedType: ascribedType, context: context)
  case let .Case(t, cases):
    return typeOf(case: t, cases: cases, context: context)
  case let .Fix(body):
    return typeOf(fix: body, context: context)
  }
}

private func typeOf(pattern: Pattern, argument: Type, context: TypeContext) -> TypeContext? {
  switch (pattern, argument) {
  case let (.Variable, type):
    return union(context, [context.count: type])
  case let (.Record(contents), .Product(types)):
    var updatedContext: TypeContext = context
    var encounteredError: Bool = false
    contents.forEach { key, value in
      if let type = types[key], let subcontext = typeOf(pattern: value, argument: type, context: updatedContext) {
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

private func typeOf(variable: Int, context: TypeContext) -> TypeResult {
  if let type = context[variable] {
    return .right(context, type)
  } else {
    return .left(.message("Could not find \(variable) in \(context)"))
  }
}

private func typeOf(parameter: String, body: Term, type: Type, context: TypeContext) -> TypeResult {
  let bodyType = typeOf(term: body, context: add(type: type, to: context))
  switch bodyType {
  case let .right(_, returnType):
    return .right(context, .Function(parameterType: type, returnType: returnType))
  case let .left(error):
    return .left(error)
  }
}

private func typeOf(application: (left: Term, right: Term), context: TypeContext) -> TypeResult {
  let leftType = typeOf(term: application.left, context: context)
  let rightType = typeOf(term: application.right, context: context)
  switch (leftType, rightType) {
  case let (.right(_, .Function(parameterType, returnType)), .right(_, argumentType)) where parameterType == argumentType:
    return .right(context, returnType)
  case let (.right(_, .Function(parameterType, returnType)), .right(_, argumentType)):
    return .left(.message("Incorrect application types, function: \(parameterType, returnType), argument: \(argumentType)"))
  case let (.right(c1, t1), .right(c2, t2)):
    return .left(.message("Incorrect application\n\(application.left) :: \(t1) - \(c1) \n\(application.right) :: \(t2) - \(c2)"))
  case let (.right, .left(error)):
    return .left(.message("Could not parse type of \(application.right)\n\(error)"))
  case let (.left(error), .right):
    return .left(.message("Could not parse type of \(application.left)\n\(error)"))
  case (.left, .left):
    return .left(.message("Could not parse type of \(application.left) or \(application.right)"))
  default:
    return .left(.message("Unknown error: \(application)"))
  }
}

private func typeOf(isZero: Term, context: TypeContext) -> TypeResult {
  let result = typeOf(term: isZero, context: context)
  switch result {
  case let .right(_, type) where type == .Integer:
    return .right(context, .Boolean)
  default:
    return .left(.message("isZero called on non-integer argument \(result)"))
  }
}

private func typeOf(predOrSucc: Term, context: TypeContext) -> TypeResult {
  let result = typeOf(term: predOrSucc, context: context)
  switch result {
  case let .right(_, type) where type == .Integer:
    return .right(context, .Integer)
  default:
    return .left(.message("pred/succ called on non-integer term: \(result)"))
  }
}

private func typeOf(ifElse: (conditional: Term, trueBranch: Term, falseBranch: Term), context: TypeContext) -> TypeResult {
  let conditionalResult = typeOf(term: ifElse.conditional, context: context)
  let trueBranch = typeOf(term: ifElse.trueBranch, context: context)
  let falseBranch = typeOf(term: ifElse.falseBranch, context: context)
  switch conditionalResult {
  case let .right(_, type) where type == .Boolean:
    switch (trueBranch, falseBranch) {
    case let (.right(_, t1), .right(_, t2)) where t1 == t2:
      return .right(context, t1)
    default:
      return .left(.message("Type of if branches don't match: \(trueBranch),\(falseBranch)"))
    }
  case let .right(_, type):
    return .left(.message("Incorrect type of conditional: \(type)"))
  case let .left(message):
    return .left(message)
  }
}

private func typeOf(tuple contents: [String:Term], context: TypeContext) -> TypeResult {
  var types: [String:Type] = [:]
  var encounteredError = false
  contents.forEach { (key, value) in
    switch typeOf(term: value, context: context) {
    case let .right(type):
      types[key] = type.1
      break
    case .left:
      encounteredError = true
      break
    }
  }

  if encounteredError {
    return .left(.message("Tuple contents has incorrect type."))
  } else {
    return .right(context, .Product(types))
  }
}

private func typeOf(letTerm pattern: Pattern, argument: Term, body: Term, context: TypeContext) -> TypeResult {
  switch typeOf(term: argument, context: context) {
  case let .right(_, type):
    if let patternContext = typeOf(pattern: pattern, argument: type, context: [:]) {
      // Shift the current type context to accommodate the terms typed by the pattern.
      return typeOf(term: body, context: add(pattern: patternContext, to: context))
    } else {
      return .left(.message("Incorrect pattern types."))
    }
  default:
    return .left(.message("Couldn't typecheck pattern argument \(argument)"))
  }
}

private func typeOf(tag label: String, term: Term, ascribedType: Type, context: TypeContext) -> TypeResult {
  switch (typeOf(term: term, context: context), ascribedType) {
  case let (.right(_, type), .Sum(labeledTypes)) where type == labeledTypes[label]:
    return .right(context, ascribedType)
  default:
    return .left(.message("Couldn't typecheck tag."))
  }
}

private func typeOf(case term: Term, cases: [String:Case], context: TypeContext) -> TypeResult {
  switch typeOf(term: term, context: context) {
  case let .right(_, .Sum(sumTypes)):
    let deducedTypes = sumTypes.flatMap { (label, labeledType) -> (String, Type)? in
      if let variantCase = cases[label] {
        switch typeOf(term: variantCase.term, context: add(type: labeledType, to: context)) {
        case let .right(_, deducedType):
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
    
    if filteredTypes.isEmpty && deducedTypes.count == sumTypes.count {
      return .right(context, deducedTypes.first!.1)
    } else {
      return .left(.message("Couldn't typecheck case, cases that didn't match: \(deducedTypes)."))
    }
  default:
    return .left(.message("Couldn't typecheck case."))
  }
}

private func typeOf(fix term: Term, context: TypeContext) -> TypeResult {
  switch typeOf(term: term, context: context) {
  case let .right(_, .Function(parameterType, returnType)) where parameterType == returnType:
    return .right(context, returnType)
  default:
    return .left(.message("Couldn't typecheck fix."))
  }
}
