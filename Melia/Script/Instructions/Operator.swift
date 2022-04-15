//
//  Operator.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import Foundation

protocol Operator: Instruction {
    func apply(_ lhs: Value, _ rhs: Value) -> Value
}

extension Operator {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let rhs = newContext.stack.removeLast()
        let lhs = newContext.stack.removeLast()
        newContext.stack.append(apply(lhs, rhs))
        return newContext
    }
}

func operatorNamed(_ name: String) throws -> Operator {
    switch name {
    case "+":
        return Add()
    case "-":
        return Substract()
    case "*":
        return Multiply()
    case "/":
        return Divide()
    case "&&", "and":
        return And()
    case "||", "or":
        return Or()
    default:
        throw LookUpError.badName(name)
    }
}
