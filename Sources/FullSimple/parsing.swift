import Foundation
import Parswift

fileprivate enum Keyword: String {
  // Built ins
  case IF = "if"
  case THEN = "then"
  case ELSE = "else"
  case SUCC = "succ"
  case PRED = "pred"
  case ISZERO = "isZero"
  case FIX = "fix"
  case LETREC = "letrec"
  // Values
  case ZERO = "0"
  case UNIT = "unit"
  case FALSE = "false"
  case TRUE = "true"
  // Base Types
  case BOOL = "bool"
  case INT = "int"
  case ARROW = "->"
  // Special characters
  case COLON = ":"
  case SEMICOLON = ";"
  case PERIOD = "."
  case COMMA = ","
  case BACKSLASH = "\\"
  case OPEN_TUPLE = "{"
  case CLOSE_TUPLE = "}"
  case OPEN_PAREN = "("
  case CLOSE_PAREN = ")"
  case OPEN_ANGLE = "<"
  case CLOSE_ANGLE = ">"
  case EQUALS = "="
  case BAR = "|"
  // Extensions
  case AS = "as"
  case WILD = "_"
  case LET = "let"
  case IN = "in"
  case CASE = "case"
  case OF = "of"
  case CASE_ARROW = "=>"
}

private typealias TermParser = Parser<Term, String.CharacterView, ParseContext>
private typealias TypeParser = Parser<Type, String.CharacterView, ParseContext>
private typealias StringParser = Parser<String, String.CharacterView, ParseContext>
private typealias TypeBindingParser = Parser<(String, Type), String.CharacterView, ParseContext>

public func parse(input: String, context: ParseContext) -> Either<ParseError, (Term, ParseContext)> {
  return parse(input: input.characters, with: lind, userState: context, fileName: "")
}

private func lind() -> TermParser {
  return (sequence <* endOfInput)()
}

private func sequence() -> TermParser {
  return (chainl1(parser: topLevelItem,
                 oper: keyword(.SEMICOLON)
                  *> create(x: { t1, t2 in
                    let abstraction: Term = .Abstraction(parameter: "_",
                                                         parameterType: .Unit,
                                                         body: shift(1, 0, t2))
                    return .Application(left: abstraction, right: t1)
                  }))
    <* skipMany(parser: keyword(.SEMICOLON)))()
}

private func topLevelItem() -> TermParser {
  return (binding <|> term)()
}

private func term() -> TermParser {
  return chainl1(parser: nonApplicationTerm,
                 oper: string(string: " ") *> spaces *> create(x: { t1, t2 in .Application(left: t1, right: t2) }))()
}

private func binding() -> TermParser {
  return (attempt(parser: termBinding <|> (typeBinding *> create(x: .Unit))))()
}

private func typeBinding() -> TermParser {
  return (typeIdentifier >>- { name in
    return keyword(.EQUALS) *> type >>- { type in
      return modifyState(f: addToContext(type: type, named: name)) *> create(x: .Unit)
    }
  })()
}

private func termBinding() -> TermParser {
  return (identifier >>- { name in
    return userState >>- { savedContext in
      return keyword(.EQUALS) *> term >>- { term in
        return modifyState(f: addToContext(term: term, named: name)) *> userState >>- { newState in
          if savedContext.namedTerms.count == newState.namedTerms.count {
            return fail(message: "Trying to re-bind \(name)")
          } else {
            return create(x: .Unit)
          }
        }
      }
    }
    })()
}

private func nonApplicationTerm() -> TermParser {
  return (atom >>- { term in
    // After an atom is parsed, check if there is an ascription.
    return ascription >>- { type in
      let body: Term = .Variable(name: "x", index: 0)
      let abstraction: Term = .Abstraction(parameter: "x", parameterType: type, body: body)
      return create(x: .Application(left: abstraction, right: term))
      }
      // Check for a projection if there was no ascription.
      <|> projection(term: term)
      // If no projection or ascription, return the atom.
      <|> create(x: term)
    })()
}

private func projection(term: Term) -> () -> TermParser {
  return keyword(.PERIOD) *> separate(parser: identifier, by: keyword(.PERIOD)) >>- { identifiers in
    var term = term
    identifiers.forEach { projection in
      let pattern: Pattern = .Record([projection:.Variable(name: "x")])
      term = .Let(pattern: pattern, argument: term, body: .Variable(name: "x", index: 0))
    }
    return create(x: term)
  }
}

// MARK: - Abbreviations

private func abbreviation() -> TypeBindingParser {
  return (identifier >>- { name in type >>- { type in create(x: (name, type)) }})()
}

// MARK: - Atoms

private func atom() -> TermParser {
  return ((keyword(.OPEN_PAREN) *> sequence <* keyword(.CLOSE_PAREN)) <|> builtIn <|> value)()
}

// MARK: - Ascription

fileprivate func ascription() -> TypeParser {
  return (As *> type)()
}

fileprivate func As() -> StringParser {
  return keyword(.AS)()
}

// MARK: - Assignment

fileprivate func Let() -> TermParser {
  return (keyword(.LET) *> pattern >>- { letPattern in
    return keyword(.EQUALS) *> term >>- { t1 in
      return userState >>- { savedContext in
        return modifyState(f: shiftContext(pattern: letPattern)) *> keyword(.IN) *> term >>- { t2 in
          return modifyState(f: { _ in savedContext}) *> create(x: .Let(pattern: letPattern, argument: t1, body: t2))
        }
      }
    }
    })()
}


// MARK: Patterns

private func pattern() -> Parser<Pattern, String.CharacterView, ParseContext> {
  return (attempt(parser: identifier >>- { name in create(x: .Variable(name: name)) })
    <|> (keyword(.OPEN_TUPLE) *>
      separate(parser: patternEntry,
               byAtLeastOne: keyword(.COMMA)) >>- { contents in
                var values: [String:Pattern] = [:]
                var counter = 0
                contents.forEach {
                  if $0.0 == "" {
                    values[String(counter)] = $0.1
                  } else {
                    values[$0.0] = $0.1
                  }
                  counter = counter + 1
                }
                return create(x: .Record(values))
      }
      <* keyword(.CLOSE_TUPLE)))()
}

fileprivate func patternEntry() -> Parser<(String, Pattern), String.CharacterView, ParseContext> {
  return (
    attempt(parser: identifier >>- { name in keyword(.COLON) *> pattern >>- { p in create(x: (name, p)) } })
      <|> attempt(parser: pattern >>- { p in create(x: ("", p)) })
    )()
}

// MARK: - Built Ins

fileprivate func builtIn() -> TermParser {
  return (fix <|> succ <|> pred <|> isZero <|> ifElse <|> Let <|> variantCase)()
}

private func succ() -> TermParser {
  return (keyword(.SUCC) *> spaces *> term >>- { t in create(x: .Succ(t)) })()
}

private func pred() -> TermParser {
  return (keyword(.PRED) *> spaces *> term >>- { t in create(x: .Pred(t)) })()
}

private func isZero() -> TermParser {
  return (keyword(.ISZERO) *> spaces *> term >>- { t in create(x: .IsZero(t)) })()
}

private func fix() -> TermParser {
  return ((keyword(.FIX) *> term >>- { t in create(x: .Fix(t)) })
    // The derived convenience form of fix.
    <|> keyword(.LETREC) *> identifier <* keyword(.COLON) >>- { name in
      return type >>- { termType in
        return keyword(.EQUALS) *> term >>- { t in
          return keyword(.IN) *> term >>- { body in
            let derivedTerm: Term = .Fix(.Abstraction(parameter: "x", parameterType: termType, body: t))
            return create(x: .Let(pattern: .Variable(name: name), argument: derivedTerm, body: body))
          }
        }
      }
    }
  )()
}


// MARK: Context Modifications

private func shiftContext(name: String) -> (ParseContext) -> ParseContext {
  return { context in
    var terms: TermContext = [:]
    context.terms.forEach { existingName, index in
      terms[existingName] = index + 1
    }
    terms[name] = 0
    return ParseContext(terms: terms, types: context.types, namedTypes: context.namedTypes, namedTerms: context.namedTerms)
  }
}

private func shiftContext(pattern: Pattern) -> (ParseContext) -> ParseContext {
  return { context in
    var terms: TermContext = [:]
    context.terms.forEach { existingName, index in
      terms[existingName] = index + 1
    }
    for (index, patternVariable) in pattern.variables.enumerated() {
      terms[patternVariable] = index
    }
    return ParseContext(terms: terms, types: context.types, namedTypes: context.namedTypes, namedTerms: context.namedTerms)
  }
}

private func addToContext(name: String) -> (ParseContext) -> ParseContext {
  return { context in
    if context.terms[name] != nil {
      return context
    }
    var terms = context.terms
    terms[name] = terms.count
    return ParseContext(terms: terms, types: context.types, namedTypes: context.namedTypes, namedTerms: context.namedTerms)
  }
}

private func addToContext(term: Term, named name: String) -> (ParseContext) -> ParseContext {
  return { context in
    var terms = context.terms
    var namedTerms = context.namedTerms
    if terms[name] == nil {
      terms[name] = terms.count
      namedTerms.append(term)
    } else {
      namedTerms[terms[name]!] = term
    }
    
    return ParseContext(terms: terms, types: context.types, namedTypes: context.namedTypes, namedTerms: namedTerms)
  }
}

private func addToContext(type: Type, named: String) -> (ParseContext) -> ParseContext {
  return { context in
    var namedTypes = context.namedTypes
    namedTypes[named] = type
    return ParseContext(terms: context.terms, types: context.types, namedTypes: namedTypes, namedTerms: context.namedTerms)
  }
}

// ΜARK: - Keywords

private func keyword(_ word: Keyword) -> ParserClosure<String, String.CharacterView, ParseContext> {
  return attempt(parser: spaces *> string(string: word.rawValue))
}

// ΜARK: - λ

private func lambda() -> TermParser {
  // Parse the parameter name.
  return (keyword(.BACKSLASH) *> (identifier <|> keyword(.WILD)) >>- { name in
    // Parse the type annotation of the parameter.
    return userState >>- { savedContext in
      return modifyState(f: shiftContext(name: name)) *> keyword(.COLON) *> type >>- { argumentType in
        // Parse the body.
        return keyword(.PERIOD) *> term >>- { body in
          // Unshift the state after parsing the body.
          return  modifyState(f: { _ in savedContext}) *> create(x: .Abstraction(parameter: name, parameterType: argumentType, body: body))
        }
      }
    }
    })()
}

// MARK: - If Statements

private func ifElse() -> TermParser {
  return (If *> term >>- { conditional in
    return Then *> term >>- { tBranch in
      return Else *> term >>- { fBranch in
        return create(x: .If(condition: conditional, trueBranch: tBranch, falseBranch: fBranch))
      }
    }
    })()
}

fileprivate func If() -> StringParser {
  return keyword(.IF)()
}

fileprivate func Then() -> StringParser {
  return keyword(.THEN)()
}

fileprivate func Else() -> StringParser {
  return keyword(.ELSE)()
}

// MARK: - Types

private func baseType() -> TypeParser {
  return (bool <|> int <|> unitType <|> productType <|> sumType <|> boundType)()
}

private func boundType() -> TypeParser {
  return (typeIdentifier >>- { name in
      return create(x: .Base(typeName: name))
  })()
}

fileprivate func sumType() -> TypeParser {
  return (keyword(.OPEN_ANGLE) *> separate(parser: productEntry, byAtLeastOne: keyword(.COMMA)) >>- { contents in
      var values: [String:Type] = [:]
      var counter = 0
      contents.forEach {
        if $0.0 == "" {
          values[String(counter)] = $0.1
        } else {
          values[$0.0] = $0.1
        }
        counter = counter + 1
      }
      return create(x: .Sum(values))
    }
    <* keyword(.CLOSE_ANGLE))()
}

fileprivate func productType() -> TypeParser {
  return (keyword(.OPEN_TUPLE) *>
    separate(parser: productEntry, by: keyword(.COMMA)) >>- { contents in
      var values: [String:Type] = [:]
      var counter = 0
      contents.forEach {
        if $0.0 == "" {
          values[String(counter)] = $0.1
        } else {
          values[$0.0] = $0.1
        }
        counter = counter + 1
      }
      return create(x: .Product(values))
    }
    <* keyword(.CLOSE_TUPLE))();
}

fileprivate func productEntry() -> Parser<(String, Type), String.CharacterView, ParseContext> {
  return (attempt(parser: identifier >>- { name in keyword(.COLON) *> type >>- { t in create(x: (name, t)) } })
    <|> attempt(parser: type >>- { t in create(x: ("", t)) }))()
}

private func type() -> TypeParser {
  return chainl1(parser: baseType, oper: keyword(.ARROW) *> create(x: { t1, t2 in .Function(parameterType: t1, returnType: t2)}))()
}

fileprivate func bool() -> TypeParser {
  return (keyword(.BOOL) *> create(x: .Boolean))()
}

fileprivate func int() -> TypeParser {
  return (keyword(.INT) *> create(x: .Integer))()
}

fileprivate func unitType() -> TypeParser {
  return (keyword(.UNIT) *> create(x: .Unit))()
}

// MARK: - Values

fileprivate func value() -> TermParser {
  return (True <|> False <|> zero <|> unit <|> lambda <|> tuple <|> tag <|> variable)()
}

private func unit() -> TermParser {
  return (keyword(.UNIT) *> create(x: .Unit))()
}

private func True() -> TermParser {
  return (keyword(.TRUE) *> create(x: .True))()
}

private func False() -> TermParser {
  return (keyword(.FALSE) *> create(x: .False))()
}

fileprivate func zero() -> TermParser {
  return (keyword(.ZERO) *> create(x: .Zero))()
}

fileprivate func tuple() -> TermParser {
  return (keyword(.OPEN_TUPLE) *>
    separate(parser: tupleEntry, by: keyword(.COMMA)) >>- { contents in
      var values: [String:Term] = [:]
      var counter = 0
      contents.forEach {
        if $0.0 == "" {
          values[String(counter)] = $0.1
        } else {
          values[$0.0] = $0.1
        }
        counter = counter + 1
      }
      return create(x: .Tuple(values))
    }
    <* keyword(.CLOSE_TUPLE))();
}

fileprivate func tupleEntry() -> Parser<(String, Term), String.CharacterView, ParseContext> {
  return (attempt(parser: identifier >>- { name in keyword(.COLON) *> term >>- { t in create(x: (name, t)) } })
    <|> attempt(parser: term >>- { t in create(x: ("", t)) }))()
}


// MARK: - Variables

private func identifier() -> Parser<String, String.CharacterView, ParseContext> {
  return attempt(parser: (spaces *> many1(parser: alphanumeric) >>- { x in
    let string = String(x)
    if string.lowercased().characters.first == string.characters.first {
      return create(x: String(x))
    } else {
      return fail(message: "Identifier started with uppercase letter.")
    }
    }))()
}

private func typeIdentifier() -> Parser<String, String.CharacterView, ParseContext> {
  return attempt(parser: (spaces *> many1(parser: alphanumeric) >>- { x in
    let string = String(x)
    if string.characters.first == string.uppercased().characters.first {
      return create(x: String(x))
    } else {
      return fail(message: "Typename did not begin with uppercase letter.")
    }
    }))()
}

private func variable() -> TermParser {
  return (identifier >>- { name in
    if (Keyword(rawValue: name) != nil) {
      return fail(message: "Variable \"\(name)\" is keyword")
    }
    return modifyState(f: addToContext(name: name)) *> userState >>- { state in
      let index = state.terms[name]!
      return create(x: .Variable(name: name, index: index))
    }
    })()
}

// MARK: Variants

private func tag() -> TermParser {
  return (keyword(.OPEN_ANGLE) *> identifier >>- { name in
    return keyword(.EQUALS) *> term >>- { t in
      return keyword(.CLOSE_ANGLE) *> ascription >>- { ascribedType in
        return create(x: .Tag(label: name, term: t, ascribedType: ascribedType))
      }
    }
  })()
}

private func variantCase() -> TermParser {
  return (keyword(.CASE) *> term >>- { t in
    return keyword(.OF) *> separate(parser: caseStatement, byAtLeastOne: keyword(.BAR)) >>- { cases in
      var taggedCases: [String:Case] = [:]
      cases.forEach { taggedCases[$0.label] = $0 }
      return create(x: .Case(term: t, cases: taggedCases))
    }
  })()
}

private func caseStatement() -> Parser<Case, String.CharacterView, ParseContext> {
  return (keyword(.OPEN_ANGLE) *> identifier >>- { label in
    return keyword(.EQUALS) *> identifier >>- { parameter in
      return keyword(.CLOSE_ANGLE) *> keyword(.CASE_ARROW) *> userState >>- { savedContext in
        return modifyState(f: shiftContext(name: parameter)) *> term >>- { t in
          return modifyState(f: { _ in savedContext}) *> create(x: Case(label: label, parameter: parameter, term: t))
        }
      }
    }
    })()
}
