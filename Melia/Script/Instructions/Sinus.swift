//
//  Sinus.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/11/2022.
//

import Foundation
import MeliceFramework

struct Sinus: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(Sinus.sinus(of: newContext.stack.removeLast()))
        return newContext
    }

    static func sinus(of value: Value) -> Value {
        switch value {
        case .integer(let integer):
            return .integer(Int32(sin(Double(integer))))
        case .decimal(let decimal):
            return .decimal(sin(decimal))
        case .point(let point):
            return .point(MELPoint(x: sin(point.x), y: sin(point.y)))
        default:
            return value
        }
    }

    func equals(other: Instruction) -> Bool {
        return other is Sinus
    }
}
