//
//  Else.swift
//  Melia
//
//  Created by Raphaël Calabro on 09/12/2022.
//

import Foundation

struct Else: GroupStart {
    var whenDoneSetInstructionPointerTo = 0

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.instructionPointer = whenDoneSetInstructionPointerTo
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        if let other = other as? Else {
            return whenDoneSetInstructionPointerTo == other.whenDoneSetInstructionPointerTo
        } else {
            return false
        }
    }
}
