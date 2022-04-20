//
//  MoveBy.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import Foundation

struct Move: Instruction {
    static let spriteArgument = "sprite"
    static let byArgument = "by"
    static let toArgument = "to"
    static let speedArgument = "speed"
    static let directionArgument = "direction"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var spriteName = "self"
        if case let .string(name) = context.arguments[Move.spriteArgument] {
            spriteName = name
        }
        return context
    }
}
