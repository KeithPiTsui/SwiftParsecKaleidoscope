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
 
 <params>     ::= <identifier> | <identifier>, <params>
 <prototype>  ::= <identifier> "(" <params> ")"
 <extern>     ::= "extern" <prototype> ";"
 <operator>   ::= "+" | "-" | "*" | "/" | "%"
 
 {<arguments>}  ::= {<expr>} ("," {<expr>} )*
 
 
 {<binary>}     ::= {<expr>} <operator> {<expr>}
 
 
 {<call>}       ::= <identifier> "(" {<arguments>} ")"
 {<ifelse>}     ::= "if" {<expr>} "then" {<expr>} "else" {<expr>}
 {<definition>} ::= "def" <prototype> {<expr>} ";"
 {<parenthesized Expr>} =  "(" {<expr>} ")"
 
 {<expr>} ::= ({<call>} | {<identifier>} | <number> | {<ifelse>} | {<parenthesized Expr>}) (<operator> {<expr>}).?
 
 Two issues:
 a. binary production cause left recursive
 b. binary production and number or other expr together case ealier exit.
 */

private func tokenCaseMatch(_ token: Token) -> (Token) -> Bool {
  return { inputToken in
    return inputToken.caseNum == token.caseNum
  }
}

internal let ksParserIdentifier: ParserT<String> = satisfy(tokenCaseMatch(.identifier("")))
  .fmap{ token  in if case let Token.identifier(name) = token { return name } else { return "" } }

internal let ksParserComma: ParserT<()> = satisfy(tokenCaseMatch(.comma)).fmap(terminal)
internal let ksParserSemicolon: ParserT<()> = satisfy(tokenCaseMatch(.semicolon)).fmap(terminal)

internal let ksParserLeftParen: ParserT<()> = satisfy(tokenCaseMatch(.leftParen)).fmap(terminal)

internal let ksParserRightParen: ParserT<()> = satisfy(tokenCaseMatch(.rightParen)).fmap(terminal)

internal let ksParserExternKeyword: ParserT<()> = satisfy(tokenCaseMatch(.extern)).fmap(terminal)

// <operator>   ::= "+" | "-" | "*" | "/" | "%"
internal let ksParserOperator: ParserT<BinaryOperator> = satisfy{ (token: Token) -> Bool in
  switch token {
  case .`operator`(let op):
    if case BinaryOperator.equals = op { return false } else {return true}
  default: return false
  }
  }.fmap{token in if case let Token.`operator`(op) = token {return op} else {fatalError("impossible")} }

/**
 <params>     ::= <identifier> | <identifier>, <params>
 */
internal let ksParserCommaId: ParserT<String> = ksParserComma >>- {_ in ksParserIdentifier}
internal let ksParserParams: ParserT<[String]> =
  (ksParserIdentifier >>> many(ksParserCommaId)).fmap{ [$0.0] + $0.1}


//<prototype>  ::= <identifier> "(" <params> ")"
internal let ksParserParenParams = between(ksParserLeftParen, ksParserRightParen, ksParserParams)
internal let ksParserPrototype: ParserT<Prototype> =
  (ksParserIdentifier >>> ksParserParenParams).fmap { (id, params) -> Prototype in
    Prototype(name: id, params: params)
}

//<extern>     ::= "extern" <prototype> ";"
internal let ksParserExtern: ParserT<Prototype> =
  (ksParserExternKeyword >>> ksParserPrototype >>> ksParserSemicolon)
    .fmap{(_, proto, _) in proto} <?> "Extern"

internal let ksParserIf: ParserT<()> = satisfy(tokenCaseMatch(.if)).fmap(terminal)

internal let ksParserThen: ParserT<()> = satisfy(tokenCaseMatch(.then)).fmap(terminal)

internal let ksParserElse: ParserT<()> = satisfy(tokenCaseMatch(.else)).fmap(terminal)

internal let ksParserDef: ParserT<()> = satisfy(tokenCaseMatch(.def)).fmap(terminal)

internal let ksParserNumber: ParserT<Expr> = satisfy(tokenCaseMatch(.number(0))).fmap{ (token) -> Expr in
  if case Token.number(let num) = token { return Expr.number(num) } else { fatalError("impossible") }
}

internal let ksParserVariable: ParserT<Expr> = ksParserIdentifier.fmap(Expr.variable)



/// Mark: Lazy Parser Below


/// {<binary>} ::= {<expr>} <operator> {<expr>}
internal let ksParserBinary: LazyParserT<Expr> =
  fmap(ksParserExpr >>> ksParserOperator >>> ksParserExpr) {
    (lhs, op, rhs) -> Expr in Expr.binary(lhs, op, rhs)
}


/// {<arguments>}  ::= {<expr>} ("," {<expr>} )*
internal let ksParserCommaExpr: LazyParserT<Expr> = ksParserComma >>- ksParserExpr
internal let ksParserArguments: LazyParserT<[Expr]> =
  fmap(ksParserExpr >>> many(ksParserCommaExpr)) { [$0.0] + $0.1}

/// {<call>}       ::= <identifier> "(" {<arguments>} ")"
internal let ksParserParenArguments: LazyParserT<[Expr]> =
  fmap(ksParserLeftParen >>> ksParserArguments >>> ksParserRightParen) {
    (_, args, _) in args
}

internal let ksParserCall: LazyParserT<Expr> =
  fmap(ksParserIdentifier >>> ksParserParenArguments, Expr.call) <?> "Function Call"


/// {<ifelse>}     ::= "if" {<expr>} "then" {<expr>} "else" {<expr>}
internal let ksParserIfElse: LazyParserT<Expr> =
  fmap(ksParserIf >>> ksParserExpr >>> ksParserThen >>> ksParserExpr >>>  ksParserElse >>> ksParserExpr){
    (_, expr1, _, expr2, _, expr3) -> Expr in Expr.ifelse(expr1, expr2, expr3)
} <?> "If-then-else construction"

/// {<definition>} ::= "def" <prototype> {<expr>} ";"
internal let ksParserDefinition: LazyParserT<Definition> =
  fmap(ksParserDef >>> ksParserPrototype >>> ksParserExpr >>> ksParserSemicolon) {
    (_, proto, expr, _) -> Definition in Definition(prototype: proto, expr: expr)
} <?> "Definition"

/// {<parenthesized Expr>} =  "(" {<expr>} ")"
internal let ksParserParenExpr: LazyParserT<Expr> =
  fmap(ksParserLeftParen >>> ksParserExpr >>> ksParserRightParen) {
    (_, expr, _) in expr
} <?> "Parenthesized Expression"


/// {<expr>} ::= {<binary>} | {<call>} | {<identifier>} | <number> | {<ifelse>} | {<parenthesized Expr>}

//{<expr>} ::= ({<call>} | {<identifier>} | <number> | {<ifelse>} | {<parenthesized Expr>}) (<operator> {<expr>}).?

internal func ksParserExpr () -> ParserT<Expr> {
  
  let expr_ = try_(ksParserParenExpr)
    <|>
    try_(ksParserNumber)
    <|>
    try_(ksParserCall)
    <|>
    try_(ksParserIfElse)
    <|>
    try_(ksParserVariable)
  
  
  let ret = fmap(expr_ >>> (ksParserOperator >>> ksParserExpr).?) {
    (exp1, arg1) -> Expr in
    let (opy) = arg1
    if let (op, y) = opy {
      return Expr.binary(exp1, op, y)
    } else {
      return exp1
    }
  } <?> "Expression"
  return ret()
}

internal func anize<A> (_ a : ParserT<A>) -> ParserT<Any> {
  return a.fmap{ (x) -> Any in return x }
}

internal func anize<A> (_ a : @escaping LazyParserT<A>) -> LazyParserT<Any> {
  return {a().fmap{ (x) -> Any in return x }}
}


internal let ksParserFile: LazyParserT<File> =
  fmap(many(anize(ksParserExtern)
    <|> anize(ksParserDefinition)
    <|> anize(ksParserExpr))) {
      (components :[Any]) -> File in
      let file = File()
      for component in components {
        if let extern = component as? Prototype {
          file.addExtern(extern)
        } else if let def = component as? Definition {
          file.addDefinition(def)
        } else if let expr = component as? Expr {
          file.addExpression(expr)
        }
      }
      return file
} <?> "Parse File"
