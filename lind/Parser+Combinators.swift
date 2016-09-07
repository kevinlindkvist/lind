//
//  Combinators.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

public func many<In, Ctxt, Out, Outs: RangeReplaceableCollection>(_ p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, Outs> where Outs.Iterator.Element == Out {
  return many1(p) <|> pure(Outs())
}

public func many1<In, Ctxt, Out, Outs: RangeReplaceableCollection>(_ p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, Outs> where Outs.Iterator.Element == Out {
  return (cons <^> p) <*> many(p)
}

public func skipMany<In, Ctxt, Out>(_ p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, ()> {
  return skipMany1(p) <|> pure(())
}

public func skipMany1<In, Ctxt, Out>(_ p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, ()> {
  return p *> skipMany(p)
}

public func chainl<In, Ctxt, Out>(_ p: Parser<In, Ctxt, Out>, _ op: Parser<In, Ctxt, (Out, Out) -> Out>, _ x: Out) -> Parser<In, Ctxt, Out> {
  return chainl1(p: p,op: op) <|> pure(x)
}

public func chainl1<In, Ctxt, Out>(p: Parser<In, Ctxt, Out>, op: Parser<In, Ctxt, (Out, Out) -> Out>) -> Parser<In, Ctxt, Out> {
  func rest(_ left: Out) -> Parser<In, Ctxt, Out> {
    let operParser = op >>- { (context: inout Ctxt, f: (Out,Out)->Out) in
      print(context)
      return p >>- { (_: inout Ctxt, right: Out) in
        rest(f(left, right))
      }
    }

    return operParser <|> pure(left)
  }

  return p >>- { (context, result) in
    rest(result)
  }
}

