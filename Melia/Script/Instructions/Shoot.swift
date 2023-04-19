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

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        guard let spriteManager = context.spriteManager,
            let player = spriteManager.pointee.sprites[0],
            let shootingStyle = context.arguments.shootingStyle(for: Shoot.styleArgument)
        else { return context }

        var sprite: MELSpriteRef = player
        if let from = context.arguments.sprite(for: Shoot.fromArgument) {
            sprite = from
        }

        shootingStyle.style.pointee.class.pointee.update(shootingStyle.style, sprite, MEL_PI, 1 / 60)

        return context
    }

    func equals(other: Instruction) -> Bool {
        return other is Shoot
    }
}
