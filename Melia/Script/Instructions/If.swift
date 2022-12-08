//
//  When.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import Foundation

struct If: GroupStart {
    static let testArgument = "test"

    var whenDoneSetInstructionPointerTo = 0

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let test = newContext.arguments.boolean(for: If.testArgument) ?? false
        if !test {
            newContext.instructionPointer = whenDoneSetInstructionPointerTo
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        if let other = other as? If {
            return whenDoneSetInstructionPointerTo == other.whenDoneSetInstructionPointerTo
        } else {
            return false
        }
    }
}
