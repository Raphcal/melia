//
//  Script.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct Script {
    var declare: [String: Kind]
    var states: [String: Int]
    var instructions: [Instruction]
    var initialState: String

    func run(sprite: MELSpriteRef, resumeWith oldContext: ExecutionContext? = nil) -> ExecutionContext {
        var context = oldContext ?? ExecutionContext(script: self, state: initialState)
        context.yield = false
        context.heap["self"] = .sprite(sprite)
        while !context.yield && context.instructionPointer < instructions.count {
            let oldInstructionPointer = context.instructionPointer
            context = instructions[context.instructionPointer].update(context: context)
            if context.instructionPointer == oldInstructionPointer {
                context.instructionPointer = oldInstructionPointer + 1
            }
        }
        return context
    }

    struct ExecutionContext {
        var script: Script
        var instructionPointer = 0
        var stack = [Value]()
        var heap = [String: Value]()
        var arguments = [String: Value]()
        var yield = false
        var state: String
    }
}
