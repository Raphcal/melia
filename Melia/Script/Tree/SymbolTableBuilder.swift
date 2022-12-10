//
//  SymbolTableBuilder.swift
//  Melia
//
//  Created by Raphaël Calabro on 01/05/2022.
//

import Foundation

/// Créé une table des symboles (`SymbolTable`) à partir d'un `TokenTree`.
class SymbolTableBuilder: TreeNodeVisitor {
    var symbolTable = SymbolTable(states: [], variables: [
        "self": .sprite,
        "map": .map,
        "delta": .decimal
    ])

    func visit(from node: StateNode) -> Void {
        symbolTable.states.append(node)
        node.children.accept(visitor: self)
    }

    func visit(from node: GroupNode) -> Void {
        var localVariables = [String]()
        switch node.name {
        case "during":
            symbolTable.variables["time"] = .decimal
            symbolTable.localVariables["progress"] = .decimal
            localVariables.append("progress")
        default:
            break
        }
        node.children.accept(visitor: self)
        for localVariable in localVariables {
            symbolTable.localVariables.removeValue(forKey: localVariable)
        }
    }
    
    func visit(from node: InstructionNode) -> Void {
        // Vide
    }
    
    func visit(from node: ArgumentNode) -> Void {
        // Vide
    }
    
    func visit(from node: SetNode) -> Void {
        if node.variable == "state" {
            symbolTable.variables[node.variable] = .state
        } else if !node.variable.contains(".") {
            symbolTable.variables[node.variable] = node.value.kind(symbolTable: symbolTable)
        }
    }
    
    func visit(from node: BinaryOperationNode) -> Void {
        // Vide
    }
    
    func visit(from node: UnaryOperationNode) -> Void {
        // Vide
    }
    
    func visit(from node: BracesNode) -> Void {
        // Vide
    }
    
    func visit(from node: VariableNode) -> Void {
        // Vide
    }
    
    func visit(from node: ConstantNode) -> Void {
        // Vide
    }
}

extension TokenTree {
    var symbolTable: SymbolTable {
        let builder = SymbolTableBuilder()
        children.accept(visitor: builder)
        return builder.symbolTable
    }
}

extension Array where Element == TreeNode {
    func accept(visitor: SymbolTableBuilder) {
        for element in self {
            element.accept(visitor: visitor)
        }
    }
}

extension ArgumentNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return value.kind(symbolTable: symbolTable)
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
        return symbolTable.kind(of: name)
    }
}

extension ConstantNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return value.kind
    }
}
