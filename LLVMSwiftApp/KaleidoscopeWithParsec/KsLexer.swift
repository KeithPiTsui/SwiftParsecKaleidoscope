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
  internal static let additionOperator: ParserS<Token> = char("+").fmap{_ in Token.operator(.plus)}
}
