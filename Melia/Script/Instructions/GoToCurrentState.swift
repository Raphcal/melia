//
//  LoadCurrentState.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

struct GoToCurrentState: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.instructionPointer = newContext.script.states[context.state] ?? 0
        newContext.yield = true
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is GoToCurrentState
    }
}
