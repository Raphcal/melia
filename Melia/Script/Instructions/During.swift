//
//  During.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

struct During: GroupStart, DeclareVariables {
    static let durationArgument = "duration"
    static let easeArgument = "ease"
    static let functionArgument = "function"
    static let progressVariable = "progress"
    static let timeVariable = "time"

    let variables = [During.progressVariable, During.timeVariable]

    var whenDoneSetInstructionPointerTo = 0

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context

        let ease = newContext.arguments.boolean(for: During.easeArgument) ?? false
        let duration = newContext.arguments.decimal(for: During.durationArgument) ?? 0
        let function = newContext.arguments.string(for: During.functionArgument) ?? "sin(π / 2 * x) ^ 2"
        let functionScript = TokenTree(code: "result = \(function)\n").script

        guard case let .decimal(delta) = newContext.heap["delta"] else {
            return newContext
        }
        let time = newContext.heap.decimal(for: During.timeVariable) ?? 0
        // TODO: Gérer le cas où le temps dépasse duration et réduire la valeur de delta.
        if time == duration {
            clearVariables(context: &newContext)
            newContext.instructionPointer = whenDoneSetInstructionPointerTo
        } else {
            let newTime = MELFloatMin(time + delta, duration)
            newContext.heap[During.progressVariable] = .decimal(ease ? functionScript.calculate(heap: [
                "x": .decimal(min(newTime, duration) / duration),
            ]) : newTime / duration)
            newContext.heap[During.timeVariable] = .decimal(newTime)
        }
        return newContext
    }

    func equals(other: Instruction) -> Bool {
        if let other = other as? During {
            return whenDoneSetInstructionPointerTo == other.whenDoneSetInstructionPointerTo
        } else {
            return false
        }
    }
}
