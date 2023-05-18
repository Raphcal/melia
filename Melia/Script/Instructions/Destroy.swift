//
//  Destroy.swift
//  Melia
//
//  Created by Raphaël Calabro on 18/05/2023.
//

import Foundation
import MeliceFramework

struct Destroy: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        guard let player = context.spriteManager?.pointee.sprites[0]
        else {
            return context
        }
        player.pointee.isRemoved = true
        return context
    }
    func equals(other: Instruction) -> Bool {
        return other is Destroy
    }
}
