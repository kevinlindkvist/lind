//
//  Parser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

public struct Parser<Input, Output> {
  let parse: Input -> Reply<Input, Output>
}

public func parse<Input, Output>(parser: Parser<Input, Output>, input: Input) -> Reply<Input, Output> {
  return parser.parse(input)
}

public func parseOnly<In, Out>(p: Parser<In, Out>, input: In) -> Result<Out, ParseError> {
  return parse(p, input: input).result
}

// MARK: Monad functions.

/// Returns a Parser with a .Failure Reply containing `message`.
func fail<Input, Output>(message: String) -> Parser<Input, Output> {
  return Parser { .Failure($0, [], message) }
}

/// Equivalent to Swift's flatMap. First parses the input with `parser` and
/// then passes the output to `f` and uses the result to parse the remaining 
/// input.
func >>-<Input, Output1, Output2>(parser: Parser<Input, Output1>, f: Output1 -> Parser<Input, Output2>) -> Parser<Input, Output2> {
  return Parser { input in
    switch parse(parser, input: input) {
    case let .Failure(input2, labels, message):
      return .Failure(input2, labels, message)
    case let .Done(input2, output):
      return parse(f(output), input: input2)
    }
  }
}

// Mark: Alternative functions.

/// The identity of `<|>`.
func empty<Input, Output>() -> Parser<Input, Output> {
  return fail("empty")
}

/// Attempts parsing the input with `p`, and if that fails returns the result 
/// of parsing the input with `q`.
func <|><Input, Output>(p: Parser<Input, Output>,
         @autoclosure(escaping) q: () -> Parser<Input, Output>) -> Parser<Input, Output> {
  return Parser { input in
    let reply = parse(p, input: input)
    switch reply {
      case .Failure:
        return parse(q(), input: input)
      case .Done:
        return reply
    }
  }
}

// MARK: Applicative functions.

/// Lifts `output` to `Parser<Input, Output>`.
func pure<Input, Output>(output: Output) -> Parser<Input, Output> {
  return Parser { .Done($0, output) }
}

/// Rerturns a `Parser` that parses the input with `p`, and then parses the
/// remaining input using the parser produced by `q`.
func <*><Input, Output1, Output2>(p: Parser<Input, Output1 -> Output2>, @autoclosure(escaping) q: () -> Parser<Input, Output1>) -> Parser<Input, Output2> {
  return p >>- { f in f <^> q() }
}

/// Sequences the provided actions, discarding the output of the right 
/// argument.
func <*<Input, Output1, Output2>(p: Parser<Input, Output1>,
        @autoclosure(escaping) q: () -> Parser<Input, Output2>)
  -> Parser<Input, Output1> {
    return const <^> p <*> q
}

/// Sequences the provided actions, discarding the output of the left
/// argument.
func *><Input, Output1, Output2>(p: Parser<Input, Output1>,
        @autoclosure(escaping) q: () -> Parser<Input, Output2>)
  -> Parser<Input, Output2> {
    return const(id) <^> p <*> q
}

// MARK: Functor functions.

/// Swift's `map`. Parses the input using `p`, and then applies `f` to the
/// resulting output before returning a parser with the converted output.
func <^><Input, Output1, Output2>(f: Output1 -> Output2, p: Parser<Input, Output1>) -> Parser<Input, Output2> {
  return p >>- { a in pure(f(a)) }
}

/// Same as `<^>` with the arguments flipped.
func <&><Input, Output1, Output2>(p: Parser<Input, Output1>, f: Output1 -> Output2) -> Parser<Input, Output2> {
  return f <^> p
}

/// Labels a parser with a name.
func <?><Input, Output>(p: Parser<Input, Output>, @autoclosure(escaping) label: () -> String) -> Parser<Input, Output> {
  return Parser { input in
    let reply = parse(p, input: input)
    switch reply {
    case .Done:
      return reply
    case let .Failure(input2, labels, message2):
      return .Failure(input2, cons(label())(labels), message2)
    }
  }
}

// MARK: Peek

/// Matches the first element to perform lookahead.
func peek<Input: CollectionType, Output where Input.Generator.Element == Output>() -> Parser<Input, Output> {
  return Parser { input in
    if let head = input.first {
      return .Done(input, head)
    } else {
      return .Failure(input, [], "peek")
    }
  }
}

func endOfInput<Input: CollectionType>() -> Parser<Input, ()> {
  return Parser { input in
    if input.isEmpty {
      return .Done(input, ())
    } else {
      return .Failure(input, [], "endOfInput: \(input)")
    }
  }
}

