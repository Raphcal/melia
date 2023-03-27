//
//  Random.swift
//  Melia
//
//  Created by Raphaël Calabro on 27/03/2023.
//

import Foundation
import MeliceFramework

struct Random: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(Random.random(to: newContext.stack.removeLast()))
        return newContext
    }

    static func random(to value: Value) -> Value {
        switch value {
        case .integer(let integer):
            return .integer(MELRandomInt(integer))
        case .decimal(let decimal):
            return .decimal(MELRandomFloat(decimal))
        case .point(let point):
            return .point(MELPoint(x: MELRandomFloat(point.x), y: MELRandomFloat(point.y)))
        default:
            return value
        }
    }

    func equals(other: Instruction) -> Bool {
        return other is Random
    }
}
