//
//  FillSymbolTable.swift
//  Melia
//
//  Created by Raphaël Calabro on 01/05/2022.
//

import Foundation

extension TokenTree {
    var symbolTable: SymbolTable {
        var symbolTable = SymbolTable(states: [], variables: [
            "self": .sprite,
            "map": .map,
            "delta": .decimal
        ])
        children.forEach { $0.fill(symbolTable: &symbolTable) }
        return symbolTable
    }
}

extension StateNode {
    func fill(symbolTable: inout SymbolTable) {
        symbolTable.states.append(self)

        for child in children {
            child.fill(symbolTable: &symbolTable)
        }
        children.forEach { $0.fill(symbolTable: &symbolTable) }
    }
}

extension GroupNode {
    func fill(symbolTable: inout SymbolTable) {
        switch name {
        case "during":
            symbolTable.variables["time"] = .decimal
            // TODO: Voir comment déclarer "progress" en tant que variable locale ?
            symbolTable.variables["progress"] = .decimal
        default:
            break
        }
        children.forEach { $0.fill(symbolTable: &symbolTable) }
    }
}

extension ArgumentNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return value.kind(symbolTable: symbolTable)
    }
}

extension SetNode {
    func fill(symbolTable: inout SymbolTable) {
        if !variable.contains(".") {
            symbolTable.variables[variable] = value.kind(symbolTable: symbolTable)
        }
    }
}

extension BinaryOperationNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        let lhsKind = lhs.kind(symbolTable: symbolTable)
        let rhsKind = rhs.kind(symbolTable: symbolTable)
        switch lhsKind {
        case .integer:
            switch rhsKind {
            case .integer:
                return .integer
            case .decimal:
                return .decimal
            case .point:
                return .point
            default:
                break
            }
        case .decimal:
            switch rhsKind {
            case .integer, .decimal:
                return .decimal
            case .point:
                return .point
            default:
                break
            }
        case .point:
            switch rhsKind {
            case .integer, .decimal, .point:
                return .point
            default:
                break
            }
        case .boolean:
            if rhsKind == .boolean {
                return .boolean
            }
        case .string:
            return .string
        default:
            break
        }
        return .null
    }
}

extension UnaryOperationNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return value.kind(symbolTable: symbolTable)
    }
}

extension BracesNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return child.kind(symbolTable: symbolTable)
    }
}

extension VariableNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return symbolTable.variables.valueKind(for: name)
    }
}

extension ConstantNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return value.kind
    }
}
