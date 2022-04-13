//
//  Instruction.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

protocol Instruction {
    func update(stack: inout [Value], heap: inout [String: Value], delta: MELTimeInterval)
}
