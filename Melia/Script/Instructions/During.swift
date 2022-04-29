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

        var ease: Bool
        var duration: MELTimeInterval

        if case let .decimal(d) = newContext.heap["duration"],
           case let .boolean(e) = newContext.heap["ease"] {
            duration = d
            ease = e
        } else {
            let arguments = newContext.arguments
            if case let .decimal(d) = arguments["duration"] {
                duration = d
            } else {
                print("Duration expected but found \(arguments["duration"] ?? .null), skipping during bloc")
                newContext.instructionPointer = whenDoneSetInstructionPointerTo
                return newContext
            }
            if case let .boolean(e) = arguments["ease"] {
                ease = e
            } else {
                ease = false
            }
            newContext.heap["duration"] = .decimal(duration)
            newContext.heap["ease"] = .boolean(ease)
        }
        guard case let .decimal(delta) = newContext.heap["delta"],
           case let .decimal(time) = newContext.heap["time"]
        else {
            newContext.heap["progress"] = .decimal(0)
            newContext.heap["time"] = .decimal(0)
            return newContext
        }
        // TODO: Gérer le cas le temps dépasse duration et réduire la valeur de delta.
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
