//
//  LindParser.swift
//  lind
//
//  Created by Kevin Lindkvist on 12/11/16.
//  Copyright © 2016 lindkvist. All rights reserved.
//

import Foundation
import Result

public typealias ParseResult = Result<(TermContext, Term), ParseError>

public func parse(input: String, terms: TermContext) -> ParseResult {
  return parseOnly(lind(), input: (input.unicodeScalars, terms))
}

private typealias TermParser = Parser<String.UnicodeScalarView, TermContext, Term>
private typealias TypeParser = Parser<String.UnicodeScalarView, TermContext, Type>

private func lind() -> TermParser {
  return term <* endOfInput()
}

private let term = _term()
private func _term() -> TermParser {
  return chainl1(p: nonApplicationTerm,
                 op: char(" ") *> pure( { t1, t2 in .application(left: t1, right: t2) } ))
}

private let nonApplicationTerm = _nonApplicationTerm()
private func _nonApplicationTerm() -> TermParser {
  return skipSpaces()
    *> ((char("(") *> term <* char(")"))
        <|> lambda
        <|> ifElse
        <|> succ
        <|> pred
        <|> isZero
        <|> tmTrue
        <|> tmFalse
        <|> zero
        <|> variable)
}

private let lambda = _lambda()
private func _lambda() -> TermParser {
  return (char("\\") *> identifier) >>- { ctxt, identifier in
    let boundName = String(identifier)
    var ctxt = ctxt
    ctxt.forEach { name, index in
      return ctxt[name] = index + 1
    }
    ctxt[boundName] = 0
    return ((char(":") *> type) >>- { ctxt, type in
      return ((char(".") *> term) >>- { ctxt, t in
        var ctxt = ctxt
        ctxt.forEach { name, index in
          if (index != 0) {
            ctxt[name] = index - 1
          }
        }
        ctxt.removeValue(forKey: boundName)
        return (pure(.abstraction(parameter: boundName, parameterType: type, body:t)), ctxt)
      }, ctxt)
    }, ctxt)
  }
}

private let keywords = ["if", "else", "then", "succ", "pred", "isZero", "0"]

private let ifElse = _ifElse()
private func _ifElse() -> TermParser {
  return (keyword("if") *> term) >>- { ctxt, conditional in
    return ((keyword("then") *> term) >>- { ctxt, tBranch in
      return ((keyword("else") *> term) >>- { ctxt, fBranch in
        return (pure(.ifElse(condition: conditional, trueBranch: tBranch, falseBranch: fBranch)), ctxt)
      }, ctxt)
    }, ctxt)
  }
}

private let variable = _variable()
private func _variable() -> TermParser {
  return identifier >>- { (context: NamingContext, t: String.UnicodeScalarView) in
    let id = String(t)
    if keywords.contains(id) {
      return (fail("variable was keyword"), context)
    }
    if let index = context[id] {
      return (pure(.variable(name: id, index: index)), context)
    } else {
      let index = context.count
      return (pure(.variable(name: id, index: index)), union(context, [id:index]))
    }
  }
}

private let identifier = _identifier()
private func _identifier() -> Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView> {
  let alphas = CharacterSet.alphanumerics
  return many1( satisfy { alphas.contains(UnicodeScalar($0.value)!) } )
}

private func keyword(_ str: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, NamingContext, String.UnicodeScalarView> {
  return skipSpaces() *> string(str);
}

private let baseType = _baseType()
private func _baseType() -> TypeParser {
  return (string("bool") *> pure(.boolean))
    <|> (string("int") *> pure(.integer))
}

private let type = _type()
private func _type() -> TypeParser {
  return chainl1(p: baseType, op: string("->")
    *> pure({ t1, t2 in .function(argumentType: t1, returnType: t2) }))
}

private let zero = _zero()
private func _zero() -> TermParser {
  return char("0") *> pure(.zero)
}

private let tmTrue = _true()
private func _true() -> TermParser {
  return string("true") *> pure(.tmTrue)
}

private let tmFalse = _false()
private func _false() -> TermParser {
  return string("false") *> pure(.tmFalse)
}

private let succ = _succ()
private func _succ() -> TermParser {
  return (string("succ") *> skipSpaces() *> term)
    >>- { ctxt, t in (pure(.succ(t)), ctxt) }
}

private let pred = _pred()
private func _pred() -> TermParser {
  return (string("pred") *> skipSpaces() *> term)
    >>- { ctxt, t in (pure(.pred(t)), ctxt) }
}

private let isZero = _isZero()
private func _isZero() -> TermParser {
  return (string( "isZero") *> skipSpaces() *> term)
    >>- { ctxt, t in (pure(.isZero(t)), ctxt) }
}
