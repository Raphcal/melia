//
//  SymbolTable.swift
//  Melia
//
//  Created by Raphaël Calabro on 01/05/2022.
//

import Foundation

struct SymbolTable {
    var states: [StateNode]
    var variables: [String: ValueKind]
    var localVariables = [String: ValueKind]()

    func kind(of variable: String) -> ValueKind {
        var kind = localVariables.valueKind(for: variable)
        if kind == .null {
            kind = variables.valueKind(for: variable)
        }
        return kind
    }

    func isLocalvariable(_ name: String) -> Bool {
        return localVariables.valueKind(for: name) != .null
    }
}
