//
//  Shoot.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import Foundation
import MeliceFramework

struct Shoot: Instruction {
    static let styleArgument = "style"
    static let fromArgument = "from"
    static let bulletArgument = "bullet"
    static let bulletAnimationNameArgument = "bulletAnimationName"
    static let bulletAmountArgument = "bulletAmount"
    static let bulletAmountVariationArgument = "bulletAmount"
    static let bulletSpeedArgument = "bulletSpeed"
    static let shootIntervalArgument = "shootInterval"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        guard let spriteManager = context.spriteManager,
            let player = spriteManager.pointee.sprites[0]
        else { return context }
        var newContext = context

        var definition = player.definition
        if let definitionName = context.arguments.string(for: Shoot.bulletArgument),
           let aDefinition = spriteManager.pointee.definitions.first(where: { $0.nameAsString == definitionName }) {
            definition = aDefinition
        } else if let definitionIndex = context.arguments.integer(for: Shoot.bulletArgument) {
            definition = context.spriteManager!.pointee.definitions[Int(definitionIndex)]
        }

        let sprite = MELSpriteAlloc(spriteManager, definition, player.pointee.layer)

        if let animationName = context.arguments.animationName(for: "animation"),
           let animationIndex = sprite.definition.animations.firstIndex(where: { $0.nameAsString == animationName }) {
            MELSpriteSetAnimation(sprite, MELAnimationAlloc(sprite.definition.animations.memory!.advanced(by: animationIndex)))
            let frameIndex = Int(sprite.pointee.animation.pointee.frame.atlasIndex)
            let frameRectangle = spriteManager.pointee.atlas.sources![frameIndex]
            sprite.pointee.frame.size = MELSize(frameRectangle.size)
        }
        newContext.stack.append(.sprite(sprite))
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is Shoot
    }
}
