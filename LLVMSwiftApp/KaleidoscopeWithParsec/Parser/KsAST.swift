//
//  KsAST.swift
//  LLVMSwiftApp
//
//  Created by Keith on 2018/7/19.
//  Copyright © 2018 QW. All rights reserved.
//

internal struct Prototype {
  let name: String
  let params: [String]
}

internal struct Definition {
  let prototype: Prototype
  let expr: Expr
}

internal enum Expr {
  case number(Double)
  case variable(String)
  indirect case binary(Expr, BinaryOperator, Expr)
  indirect case ifelse(Expr, Expr, Expr)
  indirect case call(String, [Expr])
}

internal final class File {
  private(set) var externs = [Prototype]()
  private(set) var definitions = [Definition]()
  private(set) var expressions = [Expr]()
  private(set) var prototypeMap = [String: Prototype]()
  
  func prototype(name: String) -> Prototype? {
    return prototypeMap[name]
  }
  
  func addExpression(_ expression: Expr) {
    expressions.append(expression)
  }
  
  func addExtern(_ prototype: Prototype) {
    externs.append(prototype)
    prototypeMap[prototype.name] = prototype
  }
  
  func addDefinition(_ definition: Definition) {
    definitions.append(definition)
    prototypeMap[definition.prototype.name] = definition.prototype
  }
}

