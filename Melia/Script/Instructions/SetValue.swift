//
//  Set.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct SetValue: Instruction {
    var path: [String]

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        if let value = newContext.stack.popLast() {
            newContext.heap.setValue(value, at: path)
        }
        return newContext
    }
}
