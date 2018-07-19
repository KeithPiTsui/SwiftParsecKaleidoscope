//
//  main.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

import Foundation

extension String: Error {}

typealias KSMainFunction = @convention(c) () -> Void

do {
  guard CommandLine.arguments.count > 1 else {
    throw "usage: kaleidoscope <file>"
  }
  
  let input = try String(contentsOfFile: CommandLine.arguments[1])
  let toks = Lexer(input: input).lex()
  let file = try Parser(tokens: toks).parseFile()
  let irGen = IRGenerator(file: file)
  try irGen.emit()
  try irGen.module.verify()
  print(irGen.module)
  
} catch {
  print("error: \(error)")
  exit(-1)
}
