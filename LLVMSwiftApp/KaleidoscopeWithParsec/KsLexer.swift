//
//  KsLexer.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

import PaversFRP
import PaversParsec

enum BinaryOperator: Character {
  case plus = "+", minus = "-",
  times = "*", divide = "/",
  mod = "%", equals = "="
}

enum Token {
  case leftParen, rightParen, def, extern, comma, semicolon, `if`, then, `else`
  case identifier(String)
  case number(Double)
  case `operator`(BinaryOperator)
}

internal enum KsLexer {
  internal static let additionOperator: ParserS<Token> = char("+").fmap{_ in Token.operator(.plus)}
  internal static let substractionOperator: ParserS<Token> = char("-").fmap{_ in Token.operator(.minus)}
  internal static let multiplicationOperator: ParserS<Token> = char("*").fmap{_ in Token.operator(.times)}
  internal static let divisionOperator: ParserS<Token> = char("/").fmap{_ in Token.operator(.divide)}
  internal static let moduloOperator: ParserS<Token> = char("%").fmap{_ in Token.operator(.mod)}
  internal static let equalityOperator: ParserS<Token> = char("%").fmap{_ in Token.operator(.equals)}
  
  internal static let leftParen: ParserS<Token> = char("(").fmap{_ in Token.leftParen}
  internal static let rightParen: ParserS<Token> = char(")").fmap{_ in Token.rightParen}
  internal static let def: ParserS<Token> = string("def").fmap{_ in Token.def}
  internal static let extern: ParserS<Token> = string("extern").fmap{_ in Token.extern}
  internal static let comma: ParserS<Token> = char(",").fmap{_ in Token.comma}
  internal static let semicolon: ParserS<Token> = char(";").fmap{_ in Token.semicolon}
  internal static let `if`: ParserS<Token> = string("if").fmap{_ in Token.if}
  internal static let then: ParserS<Token> = string("then").fmap{_ in Token.then}
  internal static let `else`: ParserS<Token> = string("else").fmap{_ in Token.else}
  
  internal static let identifier: ParserS<Token> = {
    let underscope: ParserS<Character> = char("_")
    let letter: ParserS<Character> = satisfy(CharacterSet.asciiLetters.contains)
    let digit: ParserS<Character> = satisfy(CharacterSet.asciiDecimalDigits.contains)
    let letterOrDigit = letter <|> digit
    let id: ParserS<(Character, [Character])> = (underscope <|> letter) >>> many(letterOrDigit)
    return id.fmap{Token.identifier( String([$0.0]+$0.1) ) }
  }()
  
  internal static let number: ParserS<Token> = {
    let digit: ParserS<Character> = satisfy(CharacterSet.decimalDigits.contains) <?> "digit"
    let digits = many1(digit) <?> "digits"
    let dicimalPoint: ParserS<Character> = char(".") <?> "dicimal point"
    let plusSign: ParserS<Character> = char("+") <?> "plus sign"
    let minusSign: ParserS<Character> = char("-") <?> "minus sign"
    let plusOrMinus = plusSign <|> minusSign <?> "sign"
    let decimalFactionPart = (dicimalPoint >>- digits) <?> "decimalFactionPart"
    let number =
      (plusOrMinus.? >>> digits >>> decimalFactionPart.?)
        .fmap { (sign, decimalString, fractionString) -> Double in
          let sign_ = sign ?? "+"
          let fractionPart = fractionString ?? []
          let fraction_ = String(fractionPart)
          let decimals = String(decimalString)
          let numberStr = "\(sign_)\(decimals).\(fraction_)"
          return Double(numberStr)!
        } <?> "number"
    return number.fmap(Token.number)
  }()
  
  internal static let optr: ParserS<Token> =
    (try_(additionOperator)
      <|> try_(substractionOperator)
      <|> try_(multiplicationOperator)
      <|> try_(divisionOperator)
      <|> try_(moduloOperator)
      <|> try_(equalityOperator)) <?> "operator"
  
  internal static let token: ParserS<Token> =
    optr
      <|> try_(number)
      <|> try_(leftParen)
      <|> try_(rightParen)
      <|> try_(comma)
      <|> try_(semicolon)
      <|> try_(def)
      <||> try_(extern)
      <||> try_(`if`)
      <||> try_(then)
      <||> try_(`else`)
      <||> try_(identifier)
  
  
  
  internal static let whitespace: ParserS<Character> = satisfy(CharacterSet.whitespacesAndNewlines.contains) <?> "whitespace"
  internal static let whitespaces = many(whitespace) <?> "whitespaces"
  
  internal static let whitespacesToken: ParserS<Token> = whitespaces >>- token
  
  internal static let tokenList: ParserS<[Token]> = many(whitespacesToken)
}

extension Token: Equatable {
  static func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case (.leftParen, .leftParen), (.rightParen, .rightParen),
         (.def, .def), (.extern, .extern), (.comma, .comma),
         (.semicolon, .semicolon), (.if, .if), (.then, .then),
         (.else, .else):
      return true
    case let (.identifier(id1), .identifier(id2)):
      return id1 == id2
    case let (.number(n1), .number(n2)):
      return n1 == n2
    case let (.operator(op1), .operator(op2)):
      return op1 == op2
    default:
      return false
    }
  }
}

public func parserPrioritizedLongestMatch<S, U, A>
  (_ a:@escaping LazyParser<S, U, A>,
   _ b:@escaping LazyParser<S, U, A>)
  -> LazyParser<S, U, A> {
    return {Parser { state in
      let aResult = a().unParser(state)
      let bResult = b().unParser(state)
      switch (aResult, bResult) {
      case (.consumed(let ar), .consumed(let br)):
        let aReply = ar()
        let bReply = br()
        switch (aReply, bReply) {
        case let (.ok(aValue, aState, aUser), .ok(bValue, bState, bUser)):
          return bState.statePos > aState.statePos
            ? .consumed({.ok(bValue, bState, bUser)})
            : .consumed({.ok(aValue, aState, aUser)})
          
        default: break
        }
      default: break
      }
      return (a <|> b)().unParser(state)
      
      }
    }
}

infix operator <||> : RunesApplicativeSequencePrecedence
public func <||> <S, U, A> (_ a:@escaping LazyParser<S, U, A>,
                  _ b:@escaping LazyParser<S, U, A>)
  -> LazyParser<S, U, A> {
    return parserPrioritizedLongestMatch(a, b)
}

public func <||> <S, U, A> (_ a:@escaping LazyParser<S, U, A>,
                            _ b: Parser<S, U, A>)
  -> LazyParser<S, U, A> {
    return  a <||> {b}
}


public func <||> <S, U, A> (_ a:Parser<S, U, A>,
                            _ b: @escaping LazyParser<S, U, A>)
  -> LazyParser<S, U, A> {
    return  {a} <||> b
}

public func <||> <S, U, A> (_ a: Parser<S, U, A>,
                            _ b: Parser<S, U, A>)
  -> Parser<S, U, A> {
    return  ({a} <||> {b})()
}
