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
