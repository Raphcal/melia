//
//  Instruction.swift
//  Melia
//
//  Created by Raphaël Calabro on 03/04/2022.
//

import MeliceFramework

protocol Instruction {
    func update(sprite: inout MELSprite, context: inout [String: Any], delta: MELTimeInterval)
}

struct InstructionParser {
    static func parse(code: String) -> [Instruction] {
        for line in code.lowercased().split(separator: "/") {
            guard let instructionNameEnd = line.firstIndex(where: { $0 == " " || $0 == "," })
            else {
                continue
            }
            let instructionName = line[line.startIndex ..< instructionNameEnd]
        }
        return []
    }
}
