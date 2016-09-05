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

public func parse<In, Ctxt, Out>(parser: Parser<In, Ctxt, Out>, input: (In, Ctxt)) -> Reply<In, Ctxt, Out> {
  return parser.parse(input.0, input.1)
}

public func parseOnly<In, Ctxt, Out>(p: Parser<In, Ctxt, Out>, input: (In, Ctxt)) -> Result<(Ctxt, Out), ParseError> {
  return parse(p, input: input).result
}

// MARK: Monad functions.

/// Returns a Parser with a .Failure Reply containing `message`.
func fail<In, Ctxt, Out>(message: String) -> Parser<In, Ctxt, Out> {
  return Parser { .Failure($0, [], message) }
}

/// Equivalent to Swift's flatMap. First parses the input with `parser` and
/// then passes the output to `f` and uses the result to parse the remaining 
/// input.
func >>-<In, Ctxt, Out1, Out2>(parser: Parser<In, Ctxt, Out1>,
         f: (Ctxt, Out1) -> Parser<In, Ctxt, Out2>) -> Parser<In, Ctxt, Out2> {
  return Parser { input in
    switch parse(parser, input: input) {
    case let .Failure(input2, labels, message):
      return .Failure(input2, labels, message)
    case let .Done(input2, context, output):
      return parse(f(context, output), input: (input2, context))
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
         @autoclosure(escaping) q: () -> Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, Out> {
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

/// Lifts `output` to `Parser<In, Ctxt, Out>`.
func pure<In, Ctxt, Out>(output: Out) -> Parser<In, Ctxt, Out> {
  return Parser { .Done($0.0, $0.1, output) }
}

/// Rerturns a `Parser` that parses the input with `p`, and then parses the
/// remaining input using the parser produced by `q`.
func <*><In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, Out1 -> Out2>,
         @autoclosure(escaping) q: () -> Parser<In, Ctxt, Out1>) -> Parser<In, Ctxt, Out2> {
  return p >>- { f in f.1 <^> q() }
}

/// Sequences the provided actions, discarding the output of the right 
/// argument.
func <*<In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, Out1>,
        @autoclosure(escaping) q: () -> Parser<In, Ctxt, Out2>) -> Parser<In, Ctxt, Out1> {
    return const <^> p <*> q
}

/// Sequences the provided actions, discarding the output of the left
/// argument.
func *><In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, Out1>,
        @autoclosure(escaping) q: () -> Parser<In, Ctxt, Out2>)
  -> Parser<In, Ctxt, Out2> {
    return const(id) <^> p <*> q
}

// MARK: Functor functions.

/// Swift's `map`. Parses the input using `p`, and then applies `f` to the
/// resulting output before returning a parser with the converted output.
func <^><In, Ctxt, Out1, Out2>(f: Out1 -> Out2, p: Parser<In, Ctxt, Out1>) -> Parser<In, Ctxt, Out2> {
  return p >>- { a in pure(f(a.1)) }
}

/// Same as `<^>` with the arguments flipped.
func <&><In, Ctxt, Out1, Out2>(p: Parser<In, Ctxt, Out1>, f: Out1 -> Out2) -> Parser<In, Ctxt, Out2> {
  return f <^> p
}

/// Labels a parser with a name.
func <?><In, Ctxt, Out>(p: Parser<In, Ctxt, Out>, @autoclosure(escaping) label: () -> String) -> Parser<In, Ctxt, Out> {
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

func endOfInput<Ctxt, In: CollectionType>() -> Parser<In, Ctxt, ()> {
  return Parser { input in
    if input.0.isEmpty {
      return .Done(input.0, input.1, ())
    } else {
      return .Failure(input, [], "endOfIn: \(input)")
    }
  }
}

