//
//  PushArgument.swift
//  Melia
//
//  Created by Raphaël Calabro on 14/04/2022.
//

import Foundation

struct PushArgument: Instruction {
    var name: String

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        if let value = newContext.stack.popLast() {
            newContext.arguments[name] = value
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is PushArgument
    }
}
