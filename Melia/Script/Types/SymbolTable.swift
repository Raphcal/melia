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
}
