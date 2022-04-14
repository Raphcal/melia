//
//  During.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

struct During: Instruction {
    var duration: MELTimeInterval
    var ease = false

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        if case let .decimal(delta) = newContext.heap["delta"],
           case let .decimal(time) = newContext.heap["time"] {
            let newTime = MELFloatMin(time + delta, duration)
            newContext.heap["progress"] = .decimal(ease ? MELEaseInOut(0, duration, time) : time / duration)
            newContext.heap["time"] = .decimal(newTime)
        } else {
            newContext.heap["progress"] = .decimal(0)
            newContext.heap["time"] = .decimal(0)
        }
        return newContext
    }
}
