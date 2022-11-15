//
//  Script.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct Script: Equatable {
    var states: [String: Int]
    var initialState: String
    var instructions: [Instruction]

    var executionContext: ExecutionContext {
        return ExecutionContext(script: self, state: initialState)
    }

    func executionContext(spriteManager: UnsafeMutablePointer<MELSpriteManager>) -> ExecutionContext {
        return ExecutionContext(script: self, state: initialState, spriteManager: spriteManager)
    }

    func run(sprite: MELSpriteRef? = nil, map: MELMap? = nil, delta: MELTimeInterval = 1 / 60, resumeWith oldContext: ExecutionContext? = nil) -> ExecutionContext {
        var context = oldContext ?? executionContext
        context.yield = false
        if let sprite = sprite {
            context.heap["self"] = .sprite(sprite)
        }
        if let map = map {
            context.heap["map"] = .map(map)
        }
        context.heap["delta"] = .decimal(delta)
        while !context.yield && context.instructionPointer < instructions.count {
            let oldInstructionPointer = context.instructionPointer
            context = instructions[context.instructionPointer].update(context: context)
            if context.instructionPointer == oldInstructionPointer {
                context.instructionPointer = oldInstructionPointer + 1
            }
        }
        return context
    }

    static let empty = Script(states: [:], initialState: "default", instructions: [])

    static func == (lhs: Script, rhs: Script) -> Bool {
        return lhs.states == rhs.states
        && lhs.initialState == rhs.initialState
        && lhs.instructions == rhs.instructions
    }

    struct ExecutionContext {
        var script: Script
        var instructionPointer = 0
        var stack = [Value]()
        var heap = [String: Value]()
        var arguments = [String: Value]()
        var yield = false
        var state: String
        var spriteManager: UnsafeMutablePointer<MELSpriteManager>? = nil
    }
}
