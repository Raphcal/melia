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
        if let rhs = newContext.stack.popLast(),
           let lhs = newContext.stack.popLast() {
            newContext.stack.append(apply(lhs, rhs))
        }
        return newContext
    }
}

func operatorNamed(_ name: String) throws -> Operator {
    guard let instruction = OperatorKind.named(name)?.instruction
    else {
        throw LookUpError.badName(name)
    }
    return instruction
}
