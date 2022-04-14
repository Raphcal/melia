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
        let value = newContext.stack.removeLast()
        newContext.arguments[name] = value
        return newContext
    }
}
