//
//  SquareRoot.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/11/2022.
//

import Foundation
import MeliceFramework

struct SquareRoot: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(SquareRoot.squareRoot(of: newContext.stack.removeLast()))
        return newContext
    }

    static func squareRoot(of value: Value) -> Value {
        switch value {
        case .integer(let integer):
            return .integer(Int32(sqrt(Double(integer))))
        case .decimal(let decimal):
            return .decimal(sqrt(decimal))
        case .point(let point):
            return .point(MELPoint(x: sqrt(point.x), y: sqrt(point.y)))
        default:
            return value
        }
    }

    func equals(other: Instruction) -> Bool {
        return other is SquareRoot
    }
}
