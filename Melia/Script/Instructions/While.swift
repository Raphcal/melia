//
//  While.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import Foundation

struct While: GroupStart {
    static let testArgument = "test"

    var whenDoneSetInstructionPointerTo = 0

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let test = newContext.arguments.boolean(for: While.testArgument) ?? false
        if !test {
            newContext.instructionPointer = whenDoneSetInstructionPointerTo
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        if let other = other as? While {
            return whenDoneSetInstructionPointerTo == other.whenDoneSetInstructionPointerTo
        } else {
            return false
        }
    }
}
