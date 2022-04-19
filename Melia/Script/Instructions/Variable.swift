//
//  Variable.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct Variable: Instruction {
    var path: [String]

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(newContext.heap.value(at: path))
        return newContext
    }
}