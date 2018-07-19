//
//  KsToken.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

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
