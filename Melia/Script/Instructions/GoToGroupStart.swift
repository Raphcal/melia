//
//  GoToGroupStart.swift
//  Melia
//
//  Created by Raphaël Calabro on 14/04/2022.
//

import Foundation

struct GoToGroupStart: Instruction {
    var groupStart: Int

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.instructionPointer = groupStart
        newContext.yield = true
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        if let other = other as? GoToGroupStart {
            return groupStart == other.groupStart
        } else {
            return false
        }
    }
}
