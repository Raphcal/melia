//
//  Variable.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct Variable: Instruction {
    var name: String

    func update(stack: inout [Value], heap: inout [String : Value], delta: MELTimeInterval) {
        stack.append(heap[name] ?? .null)
    }
}
