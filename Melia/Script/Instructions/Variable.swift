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
        if path.joined() == "state" {
            newContext.stack.append(.state(context.state))
        } else {
            newContext.stack.append(newContext.heap.value(at: path))
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        if let other = other as? Variable {
            return path == other.path
        } else {
            return false
        }
    }
}
