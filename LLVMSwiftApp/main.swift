//
//  main.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

import PaversParsec

let input = ParserStateS("def sqr(n) (n * n); def foo(n) (n * sqr(n * 3) + 57 * n % 2); foo(12);")
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

    if case let ParserResult.consumed(reply_) = parserResult {
      let rr_ = reply_()
      if case let .ok(file, _, _) = rr_ {
        print(file)
        let irGen = IRGenerator(file: file)
        try irGen.emit()
        irGen.module.dump()
        try irGen.module.verify()
      }
    }
  }
}

//try REPL().run()


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
