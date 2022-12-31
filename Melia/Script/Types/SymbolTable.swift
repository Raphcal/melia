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
    var constants = [String: ConstantNode]()

    func kind(of variable: String) -> ValueKind {
        if states.contains(where: { node in
            node.name == variable
        }) {
            return .state
        }
        var kind = localVariables.valueKind(for: variable)
        if kind == .null {
            kind = variables.valueKind(for: variable)
        }
        if kind == .null {
            kind = constants.valueKind(for: variable)
        }
        return kind
    }

    func isLocalVariable(_ name: String) -> Bool {
        return localVariables.valueKind(for: name) != .null
    }
}
