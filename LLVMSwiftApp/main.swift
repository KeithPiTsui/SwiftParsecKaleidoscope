//
//  main.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

import PaversParsec

let input = ParserStateS("extern sqrt(n); def foo(n) (n * sqrt(n * 200) + 57 * n % 2);")
//let input = ParserStateS("sqrt(n * 200)")
let result = KsLexer.tokenList.unParser(input)

if case let ParserResult.consumed(reply) = result {
  let rr = reply()
  if case let .ok(value, _, _) = rr {
    print(value)
    let tokenInput = ParserState<[Token],()>(stateInput: value,
                                             statePos: SourcePos(sourceName: #function),
                                             stateUser: ())
//    let parserResult: ParserResult<Reply<[Token], (), Definition>>
//      = ksParserDefinition().unParser(tokenInput)
//    let parserResult
//      = ksParserExtern.unParser(tokenInput)
    let parserResult
          = ksParserFile().unParser(tokenInput)
//    let parserResult
//      = ksParserExpr().unParser(tokenInput)
    print(parserResult)
//    print("Okay")
  }
}



//extension String: Error {}
//
//typealias KSMainFunction = @convention(c) () -> Void
//
//do {
//  guard CommandLine.arguments.count > 1 else {
//    throw "usage: kaleidoscope <file>"
//  }
//  
//  let input: String = try String(contentsOfFile: CommandLine.arguments[1])
//  let toks: [Token] = Lexer(input: input).lex()
//  let file: File = try Parser(tokens: toks).parseFile()
//  let irGen = IRGenerator(file: file)
//  try irGen.emit()
//  try irGen.module.verify()
//  print(irGen.module)
//  
//} catch {
//  print("error: \(error)")
//  exit(-1)
//}
