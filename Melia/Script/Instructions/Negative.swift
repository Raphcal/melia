//
//  Negative.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import MeliceFramework

struct Negative: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(negative(of: newContext.stack.removeLast()))
        return newContext
    }

    func negative(of value: Value) -> Value {
        switch value {
        case .integer(let integer):
            return .integer(-integer)
        case .decimal(let decimal):
            return .decimal(-decimal)
        case .point(let point):
            return .point(MELPoint(x: -point.x, y: -point.y))
        case .boolean(let boolean):
            return .boolean(!boolean)
        case .direction(let direction):
            return .direction(direction.reverse)
        default:
            return value
        }
    }

    func equals(other: Instruction) -> Bool {
        return other is Negative
    }
}
