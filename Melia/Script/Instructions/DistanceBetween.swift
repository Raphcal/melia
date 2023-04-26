//
//  DistanceBetween.swift
//  Melia
//
//  Created by Raphaël Calabro on 22/04/2023.
//

import Foundation
import MeliceFramework

struct DistanceBetween: Instruction {
    static let fromArgument = "from"
    static let toArgument = "to"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        guard let from = context.arguments.point(for: AngleBetween.fromArgument),
              let to = context.arguments.point(for: AngleBetween.toArgument)
        else {
            return context
        }
        var newContext = context
        newContext.stack.append(.decimal(MELPointDistanceToPoint(from, to)))
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        return other is DistanceBetween
    }
}
