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

        mutating func string(for name: String, or defaultValue: String) -> String {
            var value = heap.string(for: name)
            if let value = value {
                return value
            }
            value = arguments.string(for: name)
            let result = value ?? defaultValue
            heap[name] = .string(result)
            return result
        }

        mutating func string(for name: String) -> String? {
            var value = heap.string(for: name)
            if value == nil {
                value = arguments.string(for: name)
                if let value = value {
                    heap[name] = .string(value)
                }
            }
            return value
        }

        mutating func integer(for name: String, or defaultValue: Int32) -> Int32 {
            var value = heap.integer(for: name)
            if let value = value {
                return value
            }
            value = arguments.integer(for: name)
            let result = value ?? defaultValue
            heap[name] = .integer(result)
            return result
        }

        mutating func integer(for name: String) -> Int32? {
            var value = heap.integer(for: name)
            if value == nil {
                value = arguments.integer(for: name)
                if let value = value {
                    heap[name] = .integer(value)
                }
            }
            return value
        }

        mutating func decimal(for name: String, or defaultValue: Float) -> Float {
            var value = heap.decimal(for: name)
            if let value = value {
                return value
            }
            value = arguments.decimal(for: name)
            let result = value ?? defaultValue
            heap[name] = .decimal(result)
            return result
        }

        mutating func decimal(for name: String) -> Float? {
            var value = heap.decimal(for: name)
            if value == nil {
                value = arguments.decimal(for: name)
                if let value = value {
                    heap[name] = .decimal(value)
                }
            }
            return value
        }

        mutating func point(for name: String, or defaultValue: MELPoint) -> MELPoint {
            var value = heap.point(for: name)
            if let value = value {
                return value
            }
            value = arguments.point(for: name)
            let result = value ?? defaultValue
            heap[name] = .point(result)
            return result
        }

        mutating func point(for name: String) -> MELPoint? {
            var value = heap.point(for: name)
            if value == nil {
                value = arguments.point(for: name)
                if let value = value {
                    heap[name] = .point(value)
                }
            }
            return value
        }

        mutating func boolean(for name: String, or defaultValue: Bool) -> Bool {
            var value = heap.boolean(for: name)
            if let value = value {
                return value
            }
            value = arguments.boolean(for: name)
            let result = value ?? defaultValue
            heap[name] = .boolean(result)
            return result
        }

        mutating func boolean(for name: String) -> Bool? {
            var value = heap.boolean(for: name)
            if value == nil {
                value = arguments.boolean(for: name)
                if let value = value {
                    heap[name] = .boolean(value)
                }
            }
            return value
        }

        mutating func direction(for name: String, or defaultValue: MELDirection) -> MELDirection {
            var value = heap.direction(for: name)
            if let value = value {
                return value
            }
            value = arguments.direction(for: name)
            let result = value ?? defaultValue
            heap[name] = .direction(result)
            return result
        }

        mutating func direction(for name: String) -> MELDirection? {
            var value = heap.direction(for: name)
            if value == nil {
                value = arguments.direction(for: name)
                if let value = value {
                    heap[name] = .direction(value)
                }
            }
            return value
        }

        mutating func animationName(for name: String, or defaultValue: String) -> String {
            var value = heap.animationName(for: name)
            if let value = value {
                return value
            }
            value = arguments.animationName(for: name)
            let result = value ?? defaultValue
            heap[name] = .animationName(result)
            return result
        }

        mutating func animationName(for name: String) -> String? {
            var value = heap.animationName(for: name)
            if value == nil {
                value = arguments.animationName(for: name)
                if let value = value {
                    heap[name] = .animationName(value)
                }
            }
            return value
        }

        mutating func sprite(for name: String, or defaultValue: MELSpriteRef) -> MELSpriteRef {
            var value = heap.sprite(for: name)
            if let value = value {
                return value
            }
            value = arguments.sprite(for: name)
            let result = value ?? defaultValue
            heap[name] = .sprite(result)
            return result
        }

        mutating func sprite(for name: String) -> MELSpriteRef? {
            var value = heap.sprite(for: name)
            if value == nil {
                value = arguments.sprite(for: name)
                if let value = value {
                    heap[name] = .sprite(value)
                }
            }
            return value
        }
    }
}
