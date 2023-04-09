//
//  StrideTo.swift
//  Melia
//
//  Created by Raphaël Calabro on 27/03/2023.
//

import Foundation
import MeliceFramework

struct Stride: Instruction, DeclareVariables {
    static let fromArgument = "from"
    static let toArgument = "to"

    var index: Int
    var variables: [String]

    init(index: Int) {
        self.index = index
        self.variables = ["strideFrom\(index)", "strideTo\(index)"]
    }

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let progress = newContext.heap.decimal(for: "progress") ?? 0
        let from = newContext.heap[variables[0]] ?? newContext.arguments[Stride.fromArgument] ?? .decimal(0)
        let to = newContext.heap[variables[1]] ?? newContext.arguments[Stride.toArgument] ?? .decimal(0)

        newContext.heap[variables[0]] = from
        newContext.heap[variables[1]] = to
        newContext.stack.append(Stride.stride(from: from, to: to, progress: progress))
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
                    y: Stride.stride(from: lhs.y, to: rhs.y, progress: progress)))
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
        return index == (other as? Stride)?.index
    }
}
