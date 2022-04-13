//
//  Script.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

struct Script {
    var declare: [String: Kind]
    var states: [String: Int]
    var instructions: [Instruction]
}
