//
//  Pair.swift
//  PaversFRP
//
//  Created by Keith on 2018/7/11.
//  Copyright © 2018 Keith. All rights reserved.
//

public struct Pair<A, B> {
  public let first: A
  public let second: B
}

extension Pair {
  public init(_ a: A, _ b: B) {
    self.first = a
    self.second = b
  }
}

extension Pair: Equatable where A: Equatable, B: Equatable {}
extension Pair: Hashable where A: Hashable, B: Hashable {}
