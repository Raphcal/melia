//
//  MoveBy.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

struct Move: Instruction {
    static let spriteArgument = "sprite"
    static let byArgument = "by"
    static let toArgument = "to"
    static let speedArgument = "speed"
    static let directionArgument = "direction"

    static let originVariable = "origin"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let spriteName = newContext.string(for: Move.spriteArgument, or: "self")
        guard let sprite = newContext.heap.sprite(for: spriteName) else {
            return newContext
        }
        let progress = newContext.heap.decimal(for: "progress") ?? 0
        var destination = sprite.pointee.frame.origin
        if let to = newContext.point(for: Move.toArgument) {
            let origin = newContext.point(for: Move.originVariable, or: sprite.pointee.frame.origin)
            destination = origin + (to - origin) * progress
        } else if let by = newContext.point(for: Move.byArgument) {
           let origin = newContext.point(for: Move.originVariable, or: sprite.pointee.frame.origin)
           destination = origin + by * progress
        } else if let speed = newContext.point(for: Move.speedArgument),
                  let delta = newContext.heap.decimal(for: "delta") {
           destination = destination + speed * delta
        }
        MELSpriteSetFrameOrigin(sprite, destination)
        if progress == 1 {
            newContext.heap.removeValue(forKey: Move.originVariable)
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is Move
    }
}
