//
//  PaversParsecAugumention.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

import PaversFRP
import PaversParsec

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

