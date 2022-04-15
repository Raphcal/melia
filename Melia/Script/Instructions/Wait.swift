//
//  Wait.swift
//  Melia
//
//  Created by Raphaël Calabro on 14/04/2022.
//

import Foundation

struct Wait: Instruction {
    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        // Aucune action
        return context
    }
}
