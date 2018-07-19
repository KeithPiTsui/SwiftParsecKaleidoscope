//
//  RE2DFA.swift
//  ParsecMock
//
//  Created by Keith on 2018/7/17.
//  Copyright © 2018 Keith. All rights reserved.
//

import PaversFRP

public func transform<Symbol>(re: RegularExpression<Symbol>) -> ENFA<Int, Symbol> {
  switch re {
  case .epsilon:
    let transition: (Int, Symbol?) -> Set<Int> = { state, input in
      state == 1 && input == nil ? [2] : []
    }
    return ENFA<Int, Symbol>(alphabet: [],
                             transition: transition,
                             initial: 1,
                             finals: [2])
  case .empty:
    let transition: (Int, Symbol?) -> Set<Int> = { state, input in [] }
    return ENFA<Int, Symbol>(alphabet: [],
                             transition: transition,
                             initial: 1,
                             finals: [2])
  case .primitives(let a):
    let transition: (Int, Symbol?) -> Set<Int> = { state, input in
      state == 1 && input == a ? [2] : []
    }
    return ENFA<Int, Symbol>(alphabet: [a],
                             transition: transition,
                             initial: 1,
                             finals: [2])
    
  case .union(let lhs, let rhs):
    let lhsENFA = transform(re: lhs)
    
    let lhsStateCount = lhsENFA.accessibleStates.count
    let renamedLHSENFA = renamedStates(of: lhsENFA, start: 2)
    let lhsStates = renamedLHSENFA.accessibleStates
//    print(lhsStates)
    
    let rhsENFA = transform(re: rhs)
    let rhsStateCount = rhsENFA.accessibleStates.count
    let renamedRHSENFA = renamedStates(of: rhsENFA, start: lhsStateCount + 2)
    let rhsStates = renamedRHSENFA.accessibleStates
//    print(rhsStates)
    
    let finals: Set<Int> = [1 + rhsStateCount + lhsStateCount + 1]
    
    let transition: (Int, Symbol?) -> Set<Int> = { state, input in
//      print("state: \(state), input:\(input)")
      
      if state == 1 && input == nil {
//        print("go to \([renamedLHSENFA.initial, renamedRHSENFA.initial])")
        return [renamedLHSENFA.initial, renamedRHSENFA.initial]
      } else if (renamedLHSENFA.finals <> renamedRHSENFA.finals).contains(state) && input == nil {
//        print("go to \(finals)")
        return finals
      } else if lhsStates.contains(state) {
//        print("go to \(renamedLHSENFA.transition(state,input))")
        return renamedLHSENFA.transition(state,input)
      } else if rhsStates.contains(state) {
//        print("go to \(renamedRHSENFA.transition(state,input))")
        return renamedRHSENFA.transition(state,input)
      } else {
//        print("go to \([])")
        return []
      }
    }
    let enfa = ENFA<Int, Symbol>(alphabet: lhsENFA.alphabet <> rhsENFA.alphabet,
                                 transition: transition,
                                 initial: 1,
                                 finals: finals)
//    print(enfa.accessibleStates)
    
    return enfa
    
  case .concatenation(let lhs, let rhs):
    
    let lhsENFA = transform(re: lhs)
    let lhsStateCount = lhsENFA.accessibleStates.count
    let renamedLHSENFA = lhsENFA
    let lhsStates = renamedLHSENFA.accessibleStates
//    print("concatenation lhsStates:\(lhsStates)")
    
    let rhsENFA = transform(re: rhs)
    let renamedRHSENFA = renamedStates(of: rhsENFA, start: lhsStateCount + 1)
    let rhsStates = renamedRHSENFA.accessibleStates
//    print("concatenation rhsStates:\(rhsStates)")
    
    
    let finals: Set<Int> = renamedRHSENFA.finals
    
    let transition: (Int, Symbol?) -> Set<Int> = { state, input in
      if renamedLHSENFA.finals.contains(state) {
        return [renamedRHSENFA.initial]
      } else if lhsStates.contains(state) {
        return renamedLHSENFA.transition(state,input)
      } else if rhsStates.contains(state) {
        return renamedRHSENFA.transition(state,input)
      } else {
        return []
      }
    }
    return ENFA<Int, Symbol>(alphabet: lhsENFA.alphabet <> rhsENFA.alphabet,
                             transition: transition,
                             initial: 1,
                             finals: finals)
    
  case .kleeneClosure(let re):
    let enfa = transform(re: re)
    let renamedENFA = renamedStates(of: enfa, start: 2)
    let renamedENFAStates = renamedENFA.accessibleStates
//    print(renamedENFAStates)
    
    let finals: Set<Int> = [renamedENFAStates.count + 2]
    
    let transition: (Int, Symbol?) -> Set<Int> = { state, input in
      if state == 1 && input == nil {
        return [renamedENFA.initial] <> finals
      } else if renamedENFA.finals.contains(state) && input == nil {
        return [renamedENFA.initial] <> finals
      } else if renamedENFAStates.contains(state){
        return renamedENFA.transition(state, input)
      } else {
        return []
      }
    }
    
    let enfa_ = ENFA<Int, Symbol>(alphabet: renamedENFA.alphabet,
                                  transition: transition,
                                  initial: 1,
                                  finals: finals)
    
//    print(enfa_.accessibleStates)
    
    return enfa_
    
  case .parenthesis(let re):
    return transform(re: re)
  }
}



//public func transform<Sym>(res: [(re: RegularExpression<Sym>, f: () -> ())]) -> ENFA<Int, Sym> {
//  
//  let enfas_: [ENFA<Int, Sym>] = res.map(first).map(transform)
//  let dfas_: [DFA<Set<Int>, Sym>] = enfas_.map(transform)
//  let dfas: [DFA<Int, Sym>] = dfas_.map{renamedStates(of: $0, start: 1)}
//  let enfas : [ENFA<Int, Sym>] = dfas.map(transform(dfa:))
//  
//  let enfaStateCounts = enfas.map{$0.accessibleStates.count}
//  let renamedENFAsAndCount: ([ENFA<Int, Sym>], Int ) = zip(enfas, enfaStateCounts)
//    .reduce(([], 2)){ (acc, pair) -> ([ENFA<Int, Sym>], Int ) in
//    (acc.0 + [renamedStates(of: pair.0, start: acc.1)], acc.1 + pair.1)
//  }
//  
//  let renamedENFAs = renamedENFAsAndCount.0
//  let lastStateInt = renamedENFAsAndCount.1
//  let renamedENFAStates = renamedENFAs.map{$0.accessibleStates}
//  let renamedENFAFinals = renamedENFAs.map{$0.finals}
//  let renamedENFAInitials = Set(renamedENFAs.map{$0.initial})
//  let fs = res.map(second)
//  
//  let finals: Set<Int> = [lastStateInt + 1]
//  
//  
//  let transition: (Int, Sym?) -> Set<Int> = { state, input in
//    if state == 1 && input == nil {
//      return renamedENFAInitials
//    } else if Set(renamedENFAs.flatMap{$0.finals}).contains(state) && input == nil {
//      
//      if let idx = renamedENFAFinals.firstIndex(where: {$0.contains(state)}) {
//        fs[idx]()
//      }
//      return finals
//    } else if let idx = renamedENFAStates.firstIndex(where: {$0.contains(state)}) {
//      return renamedENFAs[idx].transition(state, input)
//    } else { return [] }
//  }
//  let enfa = ENFA<Int, Sym>(alphabet: Set(renamedENFAs.flatMap{$0.alphabet}),
//                               transition: transition,
//                               initial: 1,
//                               finals: finals)
//  return enfa
//}
