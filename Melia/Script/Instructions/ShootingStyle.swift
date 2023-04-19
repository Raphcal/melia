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

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        guard let type = context.arguments.string(for: ShootingStyle.typeArgument),
              let spriteManager = context.spriteManager,
              ["aimed", "circular", "straight"].contains(type)
        else {
            print("No sprite manager or bad shooting style type: \(context.arguments.string(for: ShootingStyle.typeArgument) ?? "nil")")
            return context
        }
        var newContext = context

        var definition: UnsafeMutablePointer<MELShootingStyleDefinition>
        switch type {
        case "aimed":
            definition = MELAimedShootingStyleCast(MELAimedShootingStyleDefinitionAlloc())
        case "circular":
            definition = MELCircularShootingStyleCast(MELCircularShootingStyleDefinitionAlloc())
        default:
            definition = MELStraightShootingStyleCast(MELStraightShootingStyleDefinitionAlloc())
        }

        if let origin = context.arguments.string(for: ShootingStyle.originArgument) {
            definition.pointee.origin = origin == "front" ? MELShotOriginFront : MELShotOriginCenter
        }
        if let damage = context.arguments.integer(for: ShootingStyle.damageArgument) {
            definition.pointee.damage = damage
        }
        if let bulletAmount = context.arguments.integer(for: ShootingStyle.bulletAmountArgument) {
            definition.pointee.bulletAmount = bulletAmount
        }
        if let bulletAmount = context.arguments.integer(for: ShootingStyle.bulletAmountArgument) {
            definition.pointee.bulletAmount = bulletAmount
        }
        if let bulletAmountVariation = context.arguments.integer(for: ShootingStyle.bulletAmountVariationArgument) {
            definition.pointee.bulletAmountVariation = bulletAmountVariation
        }
        if let bulletSpeed = context.arguments.decimal(for: ShootingStyle.bulletSpeedArgument) {
            definition.pointee.bulletSpeed = bulletSpeed
        }
        if let shootInterval = context.arguments.decimal(for: ShootingStyle.shootIntervalArgument) {
            definition.pointee.shootInterval = shootInterval
        }
        if let inversions = context.arguments.integer(for: ShootingStyle.inversionsArgument) {
            definition.pointee.inversions = inversions
        }
        if let inversionInterval = context.arguments.integer(for: ShootingStyle.inversionIntervalArgument) {
            definition.pointee.inversionInterval = inversionInterval
        }
        if let bulletDefinition = context.arguments.integer(for: ShootingStyle.bulletDefinitionArgument) {
            definition.pointee.bulletDefinition = bulletDefinition
        } else if let bulletDefinition = context.arguments.string(for: ShootingStyle.bulletDefinitionArgument),
                  let bulletDefinitionIndex = spriteManager.pointee.definitions.firstIndex(where: { $0.nameAsString == bulletDefinition }) {
            definition.pointee.bulletDefinition = Int32(bulletDefinitionIndex)
        }

        newContext.stack.append(.shootingStyle(ShootingStyleAndDefinition(definition: definition, spriteManager: spriteManager)))

        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is ShootingStyle
    }
}


class ShootingStyleAndDefinition {
    var definition: UnsafeMutablePointer<MELShootingStyleDefinition>
    var style: UnsafeMutablePointer<MELShootingStyle>

    init(definition: UnsafeMutablePointer<MELShootingStyleDefinition>, spriteManager: UnsafeMutablePointer<MELSpriteManager>) {
        self.definition = definition
        self.style = definition.pointee.shootingStyleAlloc(definition, spriteManager)
    }

    deinit {
        free(definition)
        free(style)
    }
}
