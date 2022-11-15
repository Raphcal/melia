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
            if path.joined() == "state" {
                switch value {
                case .state(let state):
                    newContext.state = state
                case .string(let state):
                    newContext.state = state
                default:
                    print("Bad state: \(value)")
                }
            } else {
                newContext.heap.setValue(value, at: path)
            }
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        if let other = other as? SetValue {
            return path == other.path
        } else {
            return false
        }
    }
}
