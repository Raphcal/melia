//
//  ShootingStyle.swift
//  Melia
//
//  Created by Raphaël Calabro on 18/04/2023.
//

import Foundation
import MeliceFramework

struct ShootingStyle: Instruction {
    static let typeArgument = "type"
    static let originArgument = "origin"
    static let damageArgument = "damage"
    static let bulletAmountArgument = "bulletAmount"
    static let bulletAmountVariationArgument = "bulletAmountVariation"
    static let bulletSpeedArgument = "bulletSpeed"
    static let shootIntervalArgument = "shootInterval"
    static let inversionsArgument = "inversions"
    static let inversionIntervalArgument = "inversionInterval"
    static let bulletDefinitionArgument = "bulletDefinition"
    static let bulletAnimationArgument = "bulletAnimation"
    static let animationAngleArgument = "animationAngle"
    static let translationArgument = "translation"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        guard let type = context.arguments.string(for: ShootingStyle.typeArgument),
              let spriteManager = context.spriteManager,
              ["aimed", "burst", "circular", "straight"].contains(type)
        else {
            print("No sprite manager or bad shooting style type: \(context.arguments.string(for: ShootingStyle.typeArgument) ?? "nil")")
            return context
        }
        var newContext = context

        var definition = MELShootingStyleDefinition()
        definition.animationAngle = MEL_PI_2

        if let origin = context.arguments.string(for: ShootingStyle.originArgument) {
            definition.origin = origin == "front" ? MELShotOriginFront : MELShotOriginCenter
        }
        if let damage = context.arguments.integer(for: ShootingStyle.damageArgument) {
            definition.damage = damage
        }
        if let bulletAmount = context.arguments.integer(for: ShootingStyle.bulletAmountArgument) {
            definition.bulletAmount = bulletAmount
        }
        if let bulletAmount = context.arguments.integer(for: ShootingStyle.bulletAmountArgument) {
            definition.bulletAmount = bulletAmount
        }
        if let bulletAmountVariation = context.arguments.integer(for: ShootingStyle.bulletAmountVariationArgument) {
            definition.bulletAmountVariation = bulletAmountVariation
        }
        if let bulletSpeed = context.arguments.decimal(for: ShootingStyle.bulletSpeedArgument) {
            definition.bulletSpeed = bulletSpeed
        }
        if let shootInterval = context.arguments.decimal(for: ShootingStyle.shootIntervalArgument) {
            definition.shootInterval = shootInterval
        }
        if let inversions = context.arguments.integer(for: ShootingStyle.inversionsArgument) {
            definition.inversions = inversions
        }
        if let inversionInterval = context.arguments.integer(for: ShootingStyle.inversionIntervalArgument) {
            definition.inversionInterval = inversionInterval
        }
        if let bulletDefinition = context.arguments.integer(for: ShootingStyle.bulletDefinitionArgument) {
            definition.bulletDefinition = bulletDefinition
        } else if let bulletDefinition = context.arguments.string(for: ShootingStyle.bulletDefinitionArgument),
                  let bulletDefinitionIndex = spriteManager.pointee.definitions.firstIndex(where: { $0.nameAsString == bulletDefinition }) {
            definition.bulletDefinition = Int32(bulletDefinitionIndex)
        }
        if let animationName = context.arguments.animationName(for: ShootingStyle.bulletAnimationArgument),
           let sprite = spriteManager.pointee.sprites[0],
           let animationIndex = sprite.definition.animations.firstIndex(where: { $0.nameAsString == animationName }) {
            definition.animation = Int32(animationIndex)
        } else if let animationIndex = context.arguments.integer(for: ShootingStyle.bulletAnimationArgument) {
           definition.animation = animationIndex
        }
        if let animationAngle = context.arguments.decimal(for: ShootingStyle.animationAngleArgument) {
            definition.animationAngle = animationAngle
        }
        if let translation = context.arguments.point(for: ShootingStyle.translationArgument) {
            definition.translation = translation
        }

        newContext.stack.append(.shootingStyle(ShootingStyleAndDefinition(type: type, definition: definition, spriteManager: spriteManager)))

        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is ShootingStyle
    }
}


class ShootingStyleAndDefinition {
    var definition: MELShootingStyleDefinition
    var style: UnsafeMutablePointer<MELShootingStyle>

    init(type: String, definition: MELShootingStyleDefinition, spriteManager: UnsafeMutablePointer<MELSpriteManager>) {
        self.definition = definition

        switch type {
        case "aimed":
            self.style = MELAimedShootingStyleAlloc(&self.definition, spriteManager)
        case "burst":
            self.style = MELBurstShootingStyleAlloc(&self.definition, spriteManager)
        case "circular":
            self.style = MELCircularShootingStyleAlloc(&self.definition, spriteManager)
        default:
            self.style = MELStraightShootingStyleAlloc(&self.definition, spriteManager)
        }
    }

    deinit {
        free(style)
    }
}