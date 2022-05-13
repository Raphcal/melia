//
//  During.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

struct During: GroupStart {
    var whenDoneSetInstructionPointerTo = 0

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context

        let ease = newContext.boolean(for: "ease", or: false)
        let duration: MELTimeInterval = newContext.decimal(for: "duration", or: 0)

        guard case let .decimal(delta) = newContext.heap["delta"] else {
            return newContext
        }
        let time = newContext.heap.decimal(for: "time") ?? 0
        // TODO: Gérer le cas où le temps dépasse duration et réduire la valeur de delta.
        if time == duration {
            newContext.instructionPointer = whenDoneSetInstructionPointerTo
            newContext.heap.removeValue(forKey: "duration")
            newContext.heap.removeValue(forKey: "ease")
            newContext.heap.removeValue(forKey: "progress")
            newContext.heap.removeValue(forKey: "time")
        } else {
            let newTime = MELFloatMin(time + delta, duration)
            newContext.heap["progress"] = .decimal(ease ? MELEaseInOut(0, duration, newTime) : newTime / duration)
            newContext.heap["time"] = .decimal(newTime)
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
