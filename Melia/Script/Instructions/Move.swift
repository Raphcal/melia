//
//  MoveBy.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

struct Move: Instruction, DeclareVariables {
    static let spriteArgument = "sprite"
    static let byArgument = "by"
    static let toArgument = "to"
    static let speedArgument = "speed"
    static let directionArgument = "direction"

    static let originVariable = "origin"

    let variables = [Move.originVariable]

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let spriteName = newContext.arguments.string(for: Move.spriteArgument) ?? "self"
        guard let sprite = newContext.heap.sprite(for: spriteName) else {
            return newContext
        }
        let progress = newContext.heap.decimal(for: "progress") ?? 0
        var destination = sprite.pointee.frame.origin
        if let to = newContext.arguments.point(for: Move.toArgument) {
            let origin = newContext.heap.point(for: Move.originVariable) ?? sprite.pointee.frame.origin
            newContext.heap[Move.originVariable] = .point(origin)
            destination = origin + (to - origin) * progress
        } else if let by = newContext.arguments.point(for: Move.byArgument) {
            let origin = newContext.heap.point(for: Move.originVariable) ?? sprite.pointee.frame.origin
            newContext.heap[Move.originVariable] = .point(origin)
            destination = origin + by * progress
        } else if let speed = newContext.arguments.point(for: Move.speedArgument),
                  let delta = newContext.heap.decimal(for: "delta") {
            destination = destination + speed * delta
        }
        MELSpriteSetFrameOrigin(sprite, destination)
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is Move
    }
}
