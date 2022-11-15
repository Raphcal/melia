//
//  NewSprite.swift
//  Melia
//
//  Created by Raphaël Calabro on 14/11/2022.
//

import Foundation
import MeliceFramework

struct NewSprite: Instruction {
    static let definitionArgument = "definition"
    static let animationArgument = "animation"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        guard let spriteManager = context.spriteManager,
            let player = spriteManager.pointee.sprites[0]
        else { return context }
        var newContext = context

        // REM: Pour la sauvegarde, enregistrer un type de sprite : 0 = parent, 1...n = fils. Ensuite dans le chargement, quand le type est >0, récupérer le sprite parent en trouvant le sprite correspond à l'instance du parent (ou faire sprites.count - type ?) et affecter la variable du fils correspondant.
        // REM: Le cas où la définition est différente de celle du sprite parent semble difficile à gérer pour le chargement car il faudrait modifier la méthode de chargement au niveau de la définition.
        let definitionIndex = context.arguments.integer(for: NewSprite.definitionArgument) ?? definitionIndex(sprite: player, context: context)
        let definition = context.spriteManager!.pointee.definitions[Int(definitionIndex)]

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
        return other is NewSprite
    }

    private func definitionIndex(sprite: MELSpriteRef, context: Script.ExecutionContext) -> Int32 {
        let definitionName = sprite.definition.nameAsString
        return Int32(context.spriteManager!.pointee.definitions.firstIndex(where: { $0.nameAsString == definitionName }) ?? 0)
    }
}
