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
    var strideCount = 0
    var lastSetKind = ValueKind.null

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
            strideCount = 0
        default:
            break
        }
        node.children.accept(visitor: self)
        for localVariable in localVariables {
            symbolTable.localVariables.removeValue(forKey: localVariable)
        }
    }
    
    func visit(from node: InstructionNode) -> Void {
        switch node.name {
        case "stride":
            let from = node.arguments.first { $0.name == Stride.fromArgument }?.value ?? ConstantNode(value: .decimal(0))
            let to = node.arguments.first { $0.name == Stride.toArgument }?.value ?? ConstantNode(value: .decimal(0))
            if !from.isStrideConstant || !to.isStrideConstant {
                let fromKind = from.kind(symbolTable: symbolTable)
                let toKind = to.kind(symbolTable: symbolTable)

                let kind: ValueKind
                if fromKind == toKind {
                    kind = fromKind
                } else if fromKind == .point || toKind == .point {
                    kind = .point
                } else {
                    kind = .decimal
                }
                let kindCapitalized = String(describing: kind).capitalized

                // FIXME: Pourquoi définir les 2 variables ?
                symbolTable.variables["stride\(kindCapitalized)From\(strideCount)"] = kind
                symbolTable.variables["stride\(kindCapitalized)To\(strideCount)"] = kind
                strideCount += 1
            }
        default:
            break
        }
    }
    
    func visit(from node: ArgumentNode) -> Void {
        // Vide
    }
    
    func visit(from node: SetNode) -> Void {
        if node.variable == "state" {
            symbolTable.variables[node.variable] = .state
            return
        }
        let firstDot = node.variable.firstIndex(of: ".")
        if let value = node.value as? ConstantNode,
           firstDot == nil && symbolTable.kind(of: node.variable) == .null {
            // La variable est peut-être une constante.
            symbolTable.constants[node.variable] = value
        } else if let firstDot {
            let variable = String(node.variable[node.variable.startIndex ..< firstDot])
            if let constant = symbolTable.constants[variable] {
                symbolTable.constants.removeValue(forKey: variable)
                symbolTable.variables[variable] = constant.value.kind
            }
        } else {
            symbolTable.variables[node.variable] = node.value.kind(symbolTable: symbolTable)
            symbolTable.constants.removeValue(forKey: node.variable)
        }
        node.value.accept(visitor: self)
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
