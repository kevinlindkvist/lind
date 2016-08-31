//
//  Combinators.swift
//  lind
//
//  Created by Kevin Lindkvist on 8/28/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

public func many<Input, Output, Outs: RangeReplaceableCollectionType where Outs.Generator.Element == Output>(p: Parser<Input, Output>) -> Parser<Input, Outs> {
  return many1(p) <|> pure(Outs())
}

public func many1<Input, Output, Outs: RangeReplaceableCollectionType where Outs.Generator.Element == Output>(p: Parser<Input, Output>) -> Parser<Input, Outs> {
  return cons <^> p <*> many(p)
}

public func skipMany<Input, Output>(p: Parser<Input, Output>) -> Parser<Input, ()> {
  return skipMany1(p) <|> pure(())
}

public func skipMany1<Input, Output>(p: Parser<Input, Output>) -> Parser<Input, ()> {
  return p *> skipMany(p)
}

public func chainl<In, Out>(p: Parser<In, Out>, _ op: Parser<In, (Out, Out) -> Out>, _ x: Out) -> Parser<In, Out> {
  return chainl1(p, op) <|> pure(x)
}

public func chainl1<In, Out>(p: Parser<In, Out>, _ op: Parser<In, (Out, Out) -> Out>) -> Parser<In, Out> {
  return p >>- { x in
    rec { recur in { x in
      (op >>- { f in
        p >>- { y in
          recur(f(x, y))
        }
        }) <|> pure(x)
      }}(x)
  }
}