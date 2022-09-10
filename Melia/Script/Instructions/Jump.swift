//
//  Jump.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

struct Jump: GroupStart, DeclareVariables {
    static let isJumpingVariable = "isJumping"
    static let jumpSpeedVariable = "jumpSpeed"
    // TODO: Vérifier les collisions avec le sol
    static let jumpOriginVariable = "jumpOrigin"

    static let jumpForceArgument = "force"
    static let jumpGravityArgument = "gravity"

    let variables = [String]()

    var whenDoneSetInstructionPointerTo = 0

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let spriteName = newContext.arguments.string(for: Move.spriteArgument) ?? "self"
        guard let sprite = newContext.heap.sprite(for: spriteName) else {
            return newContext
        }
        // Si un autre sprite saute, la variable s'appelle "nom_spriteIsJumping"
        let isJumpingVariable = spriteName == "self" ? Jump.isJumpingVariable : "\(sprite)IsJumping"
        let jumpSpeedVariable = spriteName == "self" ? Jump.jumpSpeedVariable : "\(sprite)JumpSpeed"
        let jumpOriginVariable = spriteName == "self" ? Jump.jumpOriginVariable : "\(sprite)JumpOrigin"
        if newContext.heap.boolean(for: isJumpingVariable) == nil {
            let jumpSpeed = newContext.arguments.decimal(for: Jump.jumpForceArgument) ?? 200
            newContext.heap[isJumpingVariable] = .boolean(true)
            newContext.heap[jumpSpeedVariable] = .decimal(-jumpSpeed)
            newContext.heap[jumpOriginVariable] = .decimal(sprite.pointee.frame.origin.y)
        }
        guard case let .decimal(delta) = newContext.heap["delta"],
              case let .decimal(jumpSpeed) = newContext.heap[jumpSpeedVariable],
              case let .decimal(origin) = newContext.heap[jumpOriginVariable] else {
            return newContext
        }
        let gravity = newContext.heap.decimal(for: Jump.jumpGravityArgument) ?? 600
        var frameOrigin = sprite.pointee.frame.origin
        frameOrigin.y += jumpSpeed * delta
        MELSpriteSetFrameOrigin(sprite, frameOrigin)
        newContext.heap[jumpSpeedVariable] = .decimal(jumpSpeed + gravity * delta)
        if sprite.pointee.frame.origin.y >= origin {
            sprite.pointee.frame.origin.y = origin
            clearVariables(context: &newContext, variableNames: [isJumpingVariable, jumpSpeedVariable, jumpOriginVariable])
            newContext.instructionPointer = whenDoneSetInstructionPointerTo
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is Jump
    }
}
