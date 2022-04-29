//
//  Instruction.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

protocol Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext
    func equals(other: Instruction) -> Bool
}

extension Instruction {
    func argument(named name: String, in context: Script.ExecutionContext, or defaultValue: String) -> String {
        if case let .string(value) = context.arguments[name] {
            return value
        } else {
            return defaultValue
        }
    }

    func argument(named name: String, in context: Script.ExecutionContext, or defaultValue: Int32) -> Int32 {
        if case let .integer(value) = context.arguments[name] {
            return value
        } else {
            return defaultValue
        }
    }

    func argument(named name: String, in context: Script.ExecutionContext, or defaultValue: Float) -> Float {
        if case let .decimal(value) = context.arguments[name] {
            return value
        } else {
            return defaultValue
        }
    }

    func argument(named name: String, in context: Script.ExecutionContext, or defaultValue: MELPoint) -> MELPoint {
        if case let .point(value) = context.arguments[name] {
            return value
        } else {
            return defaultValue
        }
    }

    func argument(named name: String, in context: Script.ExecutionContext, or defaultValue: MELSpriteRef) -> MELSpriteRef {
        if case let .sprite(value) = context.arguments[name] {
            return value
        } else {
            return defaultValue
        }
    }

    func argument(named name: String, in context: Script.ExecutionContext, or defaultValue: MELDirection) -> MELDirection {
        if case let .direction(value) = context.arguments[name] {
            return value
        } else {
            return defaultValue
        }
    }
}

extension Array where Element == Instruction {
    static func == (lhs: [Instruction], rhs: [Instruction]) -> Bool {
        if lhs.count != rhs.count {
            return false
        }
        for index in 0 ..< lhs.count {
            if !lhs[index].equals(other: rhs[index]) {
                return false
            }
        }
        return true
    }
}
