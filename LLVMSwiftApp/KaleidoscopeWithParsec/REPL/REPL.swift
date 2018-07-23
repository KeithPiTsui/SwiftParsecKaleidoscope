import PaversParsec

internal final class REPL {
  let irGen: IRGenerator
  let targetMachine: TargetMachine
  let jit: JIT
  
  typealias KaleidoscopeFnPtr = @convention(c) () -> Double
  
  init() throws {
    self.irGen = IRGenerator(file: File())
    self.targetMachine = try TargetMachine()
    self.jit = try JIT(module: irGen.module,
                       machine: self.targetMachine)
  }
  
  func run() {
    var expressionsHandled = 0
    while true {
      print("ready> ", terminator: "")
      guard let line = readLine() else {
        continue
      }
      
      guard line != "exit" else { return }
      
      do {
        print(line)
        let input = ParserStateS(line)
        print(input)
        let result = KsLexer.tokenList.unParser(input)
        if case let ParserResult.consumed(reply) = result {
          let rr = reply()
          if case let .ok(value, _, _) = rr {
            print(value)
            let tokenInput = ParserState<[Token],()>(stateInput: value,
                                                     statePos: SourcePos(sourceName: #function),
                                                     stateUser: ())
            
            let parserResult = ksParserFile().unParser(tokenInput)
            
            if case let ParserResult.consumed(reply_) = parserResult {
              let rr_ = reply_()
              if case let .ok(file, _, _) = rr_ {
                
                for extern in file.externs {
                  print("Read extern:")
                  let function = try irGen.addExtern(extern)
                  function.dump()
                }
                for def in file.definitions {
                  print("Read definition:")
                  let function = try irGen.addDefinition(def)
                  function.dump()
                }
                
                for expr in file.expressions {
                  print("Read expression:")
                  let newIRGen = IRGenerator(moduleName: "__anonymous_\(expressionsHandled)__",
                    file: irGen.file)
                  let function = try newIRGen.createREPLInput(expr,
                                                              number: expressionsHandled)
                  jit.addModule(newIRGen.module)
                  let functionAddress = jit.addressOfFunction(name: function.name)!
                  let fnPtr = unsafeBitCast(functionAddress,
                                            to: KaleidoscopeFnPtr.self)
                  print("\(fnPtr())")
                  try jit.removeModule(newIRGen.module)
                  expressionsHandled += 1
                }
              }
            }
          }
        }
      } catch {
        print("error: \(error)")
      }
    }
  }
}
