//
//  Constant.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct Constant: Instruction {
    var value: Value

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        newContext.stack.append(value)
        return newContext
    }
}
