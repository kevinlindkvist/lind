//
//  Parser.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Result

public struct Parser<In, Ctxt, Out> {
  let parse: (In, Ctxt) -> Reply<In, Ctxt, Out>
}

public func parse<In, Ctxt, Out>(_ parser: Parser<In, Ctxt, Out>, input: (In, Ctxt)) -> Reply<In, Ctxt, Out> {
  return parser.parse(input.0, input.1)
}

public func parseOnly<In, Ctxt, Out>(_ p: Parser<In, Ctxt, Out>, input: (In, Ctxt)) -> Result<(Ctxt, Out), ParseError> {
  return parse(p, input: input).result
}

// MARK: Monad functions.

/// Returns a Parser with a .Failure Reply containing `message`.
func fail<In, Ctxt, Out>(_ message: String) -> Parser<In, Ctxt, Out> {
  return Parser { .failure($0, [], message) }
}

/// Equivalent to Swift's flatMap. First parses the input with `parser` and
/// then passes the output to `f` and uses the result to parse the remaining 
/// input.
func >>-<In, Ctxt, Out1, Out2>(parser: Parser<In, Ctxt, Out1>,
         f: @escaping (Ctxt, Out1) -> (Parser<In, Ctxt, Out2>, Ctxt)) -> Parser<In, Ctxt, Out2> {
  return Parser { input in
    switch parse(parser, input: input) {
    case let .failure(input2, labels, message):
      return .failure(input2, labels, message)
    case let .done(input2, context, output):
      let result = f(context, output)
      return parse(result.0, input: (input2, result.1))
    }
  }
}

// Mark: Alternative functions.

/// The identity of `<|>`.
func empty<In, Ctxt, Out>() -> Parser<In, Ctxt, Out> {
  return fail("empty")
}

/// Attempts parsing the input with `p`, and if that fails returns the result 
/// of parsing the input with `q`.
func <|><In, Ctxt, Out>(p: Parser<In, Ctxt, Out>,
         q: @autoclosure @escaping () -> Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, Out> {
  return Parser { input in
    let reply = parse(p, input: input)
    switch reply {
      case .failure:
        return parse(q(), input: input)
      case .done:
        return reply
    }
  }
}

// MARK: Applicative functions.

/// Lifts `output` to `Parser<In, Ctxt, Out>`.
func pure<In, Ctxt, Out>(_ output: Out) -> Parser<In, Ctxt, Out> {
  return Parser { .done($0.0, $0.1, output) }
}

func pure<In, Ctxt, Out>(_ context: Ctxt, _ output: Out) -> Parser<In, Ctxt, Out> {
  return Parser { .done($0.0, context, output) }
}

/// Rerturns a `Parser` that parses the input with `p`, and then parses the
/// remaining input using the parser produced by `q`.
func <*><In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, (Out1) -> Out2>,
         q: @autoclosure @escaping () -> Parser<In, Ctxt, Out1>) -> Parser<In, Ctxt, Out2> {
  return p >>- { (ctxt, f) in ((f <^> q()), ctxt) }
}

/// Sequences the provided actions, discarding the output of the right 
/// argument.
func <*<In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, Out1>,
        q: @autoclosure @escaping () -> Parser<In, Ctxt, Out2>) -> Parser<In, Ctxt, Out1> {
    return const <^> p <*> q
}

/// Sequences the provided actions, discarding the output of the left
/// argument.
func *><In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, Out1>,
        q: @autoclosure @escaping () -> Parser<In, Ctxt, Out2>)
  -> Parser<In, Ctxt, Out2> {
    return const(id) <^> p <*> q
}

// MARK: Functor functions.

/// Swift's `map`. Parses the input using `p`, and then applies `f` to the
/// resulting output before returning a parser with the converted output.
func <^><In, Ctxt, Out1, Out2>(f: @escaping (Out1) -> Out2, p: Parser<In, Ctxt, Out1>) -> Parser<In, Ctxt, Out2> {
  return p >>- { (ctxt: Ctxt, a: Out1) in (pure(f(a)), ctxt) }
}

/// Same as `<^>` with the arguments flipped.
func <&><In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, Out1>, f: @escaping (Out1) -> Out2) -> Parser<In, Ctxt, Out2> {
  return f <^> p
}

// MARK: Peek

func endOfInput<Ctxt, In: Collection>() -> Parser<In, Ctxt, ()> {
  return Parser { input in
    if input.0.isEmpty {
      return .done(input.0, input.1, ())
    } else {
      return .failure(input, [], "endOfIn: \(input)")
    }
  }
}

