//
//  NewPoint.swift
//  Melia
//
//  Created by Raphaël Calabro on 21/05/2023.
//

import Foundation
import MeliceFramework

struct NewPoint: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(.point(MELPoint(
            x: context.arguments.decimal(for: "x") ?? context.arguments.decimal(for: "width") ?? 0,
            y: context.arguments.decimal(for: "y") ?? context.arguments.decimal(for: "height") ?? 0
        )))
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is NewPoint
    }
}
