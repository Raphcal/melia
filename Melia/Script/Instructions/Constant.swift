//
//  Constant.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct Constant: Instruction {
    var value: Value

    func update(stack: inout [Value], heap: inout [String : Value], delta: MELTimeInterval) {
        stack.append(value)
    }
}
