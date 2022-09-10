//
//  GroupStart.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import Foundation

protocol GroupStart: Instruction {
    var whenDoneSetInstructionPointerTo: Int { get set }
}

extension GroupStart {
    func clearVariables(context: inout Script.ExecutionContext, variableNames: [String] = []) {
        for variableName in variableNames {
            context.heap.removeValue(forKey: variableName)
        }
        for instruction in context.script.instructions[context.instructionPointer...] {
            if instruction is GoToGroupStart {
                return
            }
            if let instruction = instruction as? DeclareVariables {
                instruction.variables.forEach { variable in
                    context.heap.removeValue(forKey: variable)
                }
            }
        }
    }
}
