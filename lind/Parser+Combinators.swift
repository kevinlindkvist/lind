//
//  Combinators.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

public func many<In, Ctxt, Out, Outs: RangeReplaceableCollectionType where Outs.Generator.Element == Out>(p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, Outs> {
  return many1(p) <|> pure(Outs())
}

public func many1<In, Ctxt, Out, Outs: RangeReplaceableCollectionType where Outs.Generator.Element == Out>(p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, Outs> {
  return cons <^> p <*> many(p)
}

public func skipMany<In, Ctxt, Out>(p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, ()> {
  return skipMany1(p) <|> pure(())
}

public func skipMany1<In, Ctxt, Out>(p: Parser<In, Ctxt, Out>) -> Parser<In, Ctxt, ()> {
  return p *> skipMany(p)
}

public func chainl<In, Ctxt, Out>(p: Parser<In, Ctxt, Out>, _ op: Parser<In, Ctxt, (Out, Out) -> Out>, _ x: Out) -> Parser<In, Ctxt, Out> {
  return chainl1(p, op) <|> pure(x)
}

//public func chainl1<In, Ctxt, Out>(p: Parser<In, Ctxt, Out>, _ op: Parser<In, Ctxt, (Out, Out) -> Out>) -> Parser<In, Ctxt, Out> {
//  p >>- { (x: (Ctxt, Out)) in
//    rec { recur in { (x: (Ctxt, Out)) in
//      (op >>- { (f: (Ctxt, (Out, Out)->Out)) in p >>- { (y: Out) in recur(f.1(x.1, y.1)) } }) <|> pure(x.1)
//    }}
//  }
//}

