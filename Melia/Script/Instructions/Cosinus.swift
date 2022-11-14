//
//  Cosinus.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/11/2022.
//

import Foundation
import MeliceFramework

struct Cosinus: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(Cosinus.cosinus(of: newContext.stack.removeLast()))
        return newContext
    }

    static func cosinus(of value: Value) -> Value {
        switch value {
        case .integer(let integer):
            return .integer(Int32(cos(Double(integer))))
        case .decimal(let decimal):
            return .decimal(cos(decimal))
        case .point(let point):
            return .point(MELPoint(x: cos(point.x), y: cos(point.y)))
        default:
            return value
        }
    }

    func equals(other: Instruction) -> Bool {
        return other is Cosinus
    }
}
