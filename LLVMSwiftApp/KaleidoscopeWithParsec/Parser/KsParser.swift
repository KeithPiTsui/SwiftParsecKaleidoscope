//
//  KsParser.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

import PaversFRP
import PaversParsec

internal typealias ParserT<A> = Parser<[Token], (), A>
internal typealias LazyParserT<A> = () -> ParserT<A>
/**
 
 <params>     ::= <identifier>
 | <identifier>, <params>
 <prototype>  ::= <identifier> "(" <params> ")"

 <extern>     ::= "extern" <prototype> ";"
 <operator>   ::= "+" | "-" | "*" | "/" | "%"

 <binary>     ::= <expr> <operator> <expr>
 <arguments>  ::= <expr> | <expr> "," <arguments>
 
 <call>       ::= <identifier> "(" <arguments> ")"

 <ifelse>     ::= "if" <expr> "then" <expr> "else" <expr>

  <definition> ::= "def" <prototype> <expr> ";"
 */

internal let ksParserIdentifier: LazyParserT<String> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.identifier(_) = token { return true } else { return false }}){
    token  in if case let Token.identifier(name) = token { return name } else { return "" }
}

internal let ksParserComma: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.comma = token { return true } else { return false }}, terminal)

internal let ksParserLeftParen: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.leftParen = token { return true } else { return false }}, terminal)

internal let ksParserRightParen: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.rightParen = token { return true } else { return false }}, terminal)

internal let ksParserExternKeyword: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.extern = token { return true } else { return false }}, terminal)

// <operator>   ::= "+" | "-" | "*" | "/" | "%"
internal let ksParserOperator: LazyParserT<BinaryOperator> = fmap(satisfy{ (token: Token) -> Bool in
  switch token {
  case .`operator`(let op):
    if case BinaryOperator.equals = op { return false } else {return true}
  default: return false
  }
}){token in if case let Token.`operator`(op) = token {return op} else {fatalError("impossible")} }

/**
 <params>     ::= <identifier> | <identifier>, <params>
 */
internal let ksParserCommaId: LazyParserT<String> = ksParserComma >>- {_ in ksParserIdentifier}
internal let ksParserParams: LazyParserT<[String]> =
  fmap(ksParserIdentifier >>> many(ksParserCommaId)) { [$0.0] + $0.1}


//<prototype>  ::= <identifier> "(" <params> ")"
internal let ksParserParenParams = between(ksParserLeftParen, ksParserRightParen, ksParserParams)
internal let ksParserPrototype: LazyParserT<Prototype> =
  fmap(ksParserIdentifier >>> ksParserParams) { (id, params) -> Prototype in
    Prototype(name: id, params: params)
}

//<extern>     ::= "extern" <prototype> ";"
internal let ksParserExtern: LazyParserT<Prototype> = between(ksParserExternKeyword, ksParserComma, ksParserPrototype)

// <binary>     ::= <expr> <operator> <expr>
internal let ksParserBinary: LazyParserT<Expr> =
  fmap(ksParserExpr >>> ksParserOperator >>> ksParserExpr) {
    (lhs, op, rhs) -> Expr in Expr.binary(lhs, op, rhs)
}


// <arguments>  ::= <expr> | <expr> "," <arguments>
internal let ksParserCommaExpr: LazyParserT<Expr> = ksParserComma >>- {_ in ksParserExpr}
internal let ksParserArguments: LazyParserT<[Expr]> =
    fmap(ksParserExpr >>> many(ksParserCommaExpr)) { [$0.0] + $0.1}

//<call>       ::= <identifier> "(" <arguments> ")"
internal let ksParserParenArguments = between(ksParserLeftParen, ksParserRightParen, ksParserArguments)
internal let ksParserCall: LazyParserT<Expr> =
  fmap(ksParserIdentifier >>> ksParserParenArguments, Expr.call)


// <ifelse>     ::= "if" <expr> "then" <expr> "else" <expr>
internal let ksParserIf: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.if = token { return true } else { return false }}, terminal)

internal let ksParserThen: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.then = token { return true } else { return false }}, terminal)

internal let ksParserElse: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.else = token { return true } else { return false }}, terminal)

internal let ksParserIfElse: LazyParserT<Expr> =
  fmap(ksParserIf >>> ksParserExpr >>> ksParserThen >>> ksParserExpr >>>  ksParserElse >>> ksParserExpr){
    (_, expr1, _, expr2, _, expr3) -> Expr in Expr.ifelse(expr1, expr2, expr3)
}



// <definition> ::= "def" <prototype> <expr> ";"
internal let ksParserDef: LazyParserT<()> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.def = token { return true } else { return false }}, terminal)

internal let ksParserDefinition: LazyParserT<Definition> =
  fmap(ksParserDef >>> ksParserPrototype >>> ksParserExpr >>> ksParserComma) {
    (_, proto, expr, _) -> Definition in Definition(prototype: proto, expr: expr)
}

//<expr>       ::= <binary> | <call> | <identifier> | <number> | <ifelse> | "(" <expr> ")"

internal let ksParserNumber: LazyParserT<Double> = fmap(satisfy{ (token: Token) -> Bool in
  if case Token.number(_) = token { return true } else { return false }}) { (token) -> Double in
  if case Token.number(let num) = token { return num } else { fatalError("impossible") }
}

internal let ksParserVariable: LazyParserT<Expr> = fmap(ksParserIdentifier, Expr.variable)

internal let ksParserExpr: LazyParserT<Expr> = ksParserExpr_()

internal func ksParserExpr_() -> LazyParserT<Expr> {
  return  try_(ksParserBinary)
    <|> try_(ksParserCall)
    <|> try_(ksParserVariable)
    <|> try_(fmap(ksParserNumber, Expr.number))
    <|> try_(ksParserIfElse)
    <|> try_(between(ksParserLeftParen, ksParserRightParen, {ksParserExpr_()}()))
}


