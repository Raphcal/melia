//
//  Debug.swift
//  Melia
//
//  Created by Raphaël Calabro on 23/04/2023.
//

import Foundation

struct Debug: Instruction {
    static let printArgument = "print"

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        if let value = context.arguments.string(for: Debug.printArgument) {
            print("DEBUG \(value)")
        }
        return context
    }

    func equals(other: Instruction) -> Bool {
        return other is Debug
    }
}
