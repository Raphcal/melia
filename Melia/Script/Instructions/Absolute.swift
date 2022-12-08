//
//  Absolute.swift
//  Melia
//
//  Created by Raphaël Calabro on 07/12/2022.
//

import Foundation
import MeliceFramework

struct Absolute: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(Absolute.value(of: newContext.stack.removeLast()))
        return newContext
    }

    static func value(of value: Value) -> Value {
        switch value {
        case .integer(let integer):
            return .integer(abs(integer))
        case .decimal(let decimal):
            return .decimal(abs(decimal))
        case .point(let point):
            return .point(MELPoint(x: abs(point.x), y: abs(point.y)))
        default:
            return value
        }
    }

    func equals(other: Instruction) -> Bool {
        return other is Absolute
    }
}
