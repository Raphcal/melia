//
//  StrideTo.swift
//  Melia
//
//  Created by Raphaël Calabro on 27/03/2023.
//

import Foundation
import MeliceFramework

struct Stride: Instruction {
    static let fromArgument = "from"
    static let toArgument = "to"
    static let setArgument = "set"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        if let variableToSet = newContext.arguments.string(for: Stride.setArgument) {
            let path = variableToSet.components(separatedBy: ".")
            let strideFromVariable = "\(variableToSet)StrideFrom"
            let strideToVariable = "\(variableToSet)StrideTo"

            let progress = newContext.heap.decimal(for: "progress") ?? 0
            var from = newContext.heap[strideFromVariable] ?? newContext.arguments[Stride.fromArgument] ?? newContext.heap.value(at: path)
            if from == .null {
                from = .decimal(0)
            }
            let to = newContext.heap[strideToVariable] ?? newContext.arguments[Stride.toArgument] ?? .decimal(0)
            let result = Stride.stride(from: from, to: to, progress: progress)
            if progress < 1 {
                newContext.heap[strideFromVariable] = from
                newContext.heap[strideToVariable] = to
                newContext.heap.setValue(result, at: path)
            } else if newContext.heap[strideToVariable] != nil {
                newContext.heap.setValue(result, at: path)
                newContext.heap.removeValue(forKey: strideFromVariable)
                newContext.heap.removeValue(forKey: strideToVariable)
            }
        }
        return newContext
    }

    static func stride(from: Value, to: Value, progress: Float) -> Value {
        switch from {
        case .integer(let lhs):
            switch to {
            case .integer(let rhs):
                return .integer(Int32(Stride.stride(from: Float(lhs), to: Float(rhs), progress: progress)))
            case .decimal(let rhs):
                return .decimal(Stride.stride(from: Float(lhs), to: rhs, progress: progress))
            case .point(let rhs):
                return .point(MELPoint(
                    x: Stride.stride(from: Float(lhs), to: rhs.x, progress: progress),
                    y: Stride.stride(from: Float(lhs), to: rhs.y, progress: progress)))
            default:
                return to
            }
        case .decimal(let lhs):
            switch to {
            case .integer(let rhs):
                return .decimal(Stride.stride(from: lhs, to: Float(rhs), progress: progress))
            case .decimal(let rhs):
                return .decimal(Stride.stride(from: lhs, to: rhs, progress: progress))
            case .point(let rhs):
                return .point(MELPoint(
                    x: Stride.stride(from: lhs, to: rhs.x, progress: progress),
                    y: Stride.stride(from: lhs, to: rhs.y, progress: progress)))
            default:
                return to
            }
        case .point(let lhs):
            switch to {
            case .integer(let rhs):
                return .point(MELPoint(
                    x: Stride.stride(from: lhs.x, to: Float(rhs), progress: progress),
                    y: Stride.stride(from: lhs.y, to: Float(rhs), progress: progress)))
            case .decimal(let rhs):
                return .point(MELPoint(
                    x: Stride.stride(from: lhs.x, to: rhs, progress: progress),
                    y: Stride.stride(from: lhs.y, to: rhs, progress: progress)))
            case .point(let rhs):
                return .point(MELPoint(
                    x: Stride.stride(from: lhs.x, to: rhs.x, progress: progress),
                    y: Stride.stride(from: lhs.x, to: rhs.y, progress: progress)))
            default:
                return to
            }
        default:
            return to
        }
    }

    static func stride(from: Float, to: Float, progress: Float) -> Float {
        return from + (to - from) * progress
    }

    func equals(other: Instruction) -> Bool {
        return other is Stride
    }
}
