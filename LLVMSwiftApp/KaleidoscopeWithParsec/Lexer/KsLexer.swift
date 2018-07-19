//
//  KsLexer.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

import PaversFRP
import PaversParsec

internal enum KsLexer {
  private static let additionOperator: ParserS<Token> = char("+").fmap{_ in Token.operator(.plus)}
  private static let substractionOperator: ParserS<Token> = char("-").fmap{_ in Token.operator(.minus)}
  private static let multiplicationOperator: ParserS<Token> = char("*").fmap{_ in Token.operator(.times)}
  private static let divisionOperator: ParserS<Token> = char("/").fmap{_ in Token.operator(.divide)}
  private static let moduloOperator: ParserS<Token> = char("%").fmap{_ in Token.operator(.mod)}
  private static let equalityOperator: ParserS<Token> = char("%").fmap{_ in Token.operator(.equals)}
  
  private static let leftParen: ParserS<Token> = char("(").fmap{_ in Token.leftParen}
  private static let rightParen: ParserS<Token> = char(")").fmap{_ in Token.rightParen}
  private static let def: ParserS<Token> = string("def").fmap{_ in Token.def}
  private static let extern: ParserS<Token> = string("extern").fmap{_ in Token.extern}
  private static let comma: ParserS<Token> = char(",").fmap{_ in Token.comma}
  private static let semicolon: ParserS<Token> = char(";").fmap{_ in Token.semicolon}
  private static let `if`: ParserS<Token> = string("if").fmap{_ in Token.if}
  private static let then: ParserS<Token> = string("then").fmap{_ in Token.then}
  private static let `else`: ParserS<Token> = string("else").fmap{_ in Token.else}
  
  private static let identifier: ParserS<Token> = {
    let underscope: ParserS<Character> = char("_")
    let letter: ParserS<Character> = satisfy(CharacterSet.asciiLetters.contains)
    let digit: ParserS<Character> = satisfy(CharacterSet.asciiDecimalDigits.contains)
    let letterOrDigit = letter <|> digit
    let id: ParserS<(Character, [Character])> = (underscope <|> letter) >>> many(letterOrDigit)
    return id.fmap{Token.identifier( String([$0.0]+$0.1) ) }
  }()
  
  private static let number: ParserS<Token> = {
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
  
  private static let optr: ParserS<Token> =
    (try_(additionOperator)
      <|> try_(substractionOperator)
      <|> try_(multiplicationOperator)
      <|> try_(divisionOperator)
      <|> try_(moduloOperator)
      <|> try_(equalityOperator)) <?> "operator"
  
  private static let token: ParserS<Token> =
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
  
  
  
  private static let whitespace: ParserS<Character> = satisfy(CharacterSet.whitespacesAndNewlines.contains) <?> "whitespace"
  private static let whitespaces = many(whitespace) <?> "whitespaces"
  
  private static let whitespacesToken: ParserS<Token> = whitespaces >>- token
  
  internal static let tokenList: ParserS<[Token]> = many(whitespacesToken)
}
