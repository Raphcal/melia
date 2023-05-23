//
//  TreeNode.swift
//  Melia
//
//  Created by Raphaël Calabro on 26/04/2022.
//

import Foundation

protocol TreeNode {
    func kind(symbolTable: SymbolTable) -> ValueKind
    func equals(_ other: TreeNode) -> Bool
    func accept<V: TreeNodeVisitor>(visitor: V) -> V.Result
}

extension TreeNode {
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return .null
    }
    func equals(_ other: TreeNode) -> Bool {
        return false
    }
}

struct StateNode: TreeNode {
    static let alwaysName = "always"
    static let constructorName = "constructor"
    static let drawName = "draw"

    var name: String
    var children: [TreeNode]

    var isConstructor: Bool {
        return name == StateNode.constructorName
    }

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct GroupNode: TreeNode {
    var name: String
    var arguments: [ArgumentNode]
    var children: [TreeNode]

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct InstructionNode: TreeNode {
    var name: String
    var arguments: [ArgumentNode]

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }

    func kind(symbolTable: SymbolTable) -> ValueKind {
        switch name {
        case "new":
            return .sprite
        case "point":
            return .point
        case "shootingStyle":
            return .shootingStyle
        case "stride":
            let fromKind = arguments.first { $0.name == Stride.fromArgument }?.value.kind(symbolTable: symbolTable) ?? .null
            let toKind = arguments.first { $0.name == Stride.toArgument }?.value.kind(symbolTable: symbolTable) ?? .null
            if fromKind == toKind {
                // Seul cas permettant de renvoyer un type integer
                return fromKind
            } else if fromKind == .point || toKind == .point {
                return .point
            } else {
                return .decimal
            }
        default:
            return .null
        }
    }
}

struct ArgumentNode: TreeNode {
    var name: String
    var value: TreeNode

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct SetNode: TreeNode {
    var variable: String
    var value: TreeNode

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct BinaryOperationNode: TreeNode {
    var lhs: TreeNode
    var `operator`: OperatorKind
    var rhs: TreeNode

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct UnaryOperationNode: TreeNode {
    var `operator`: String
    var value: TreeNode

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct BracesNode: TreeNode {
    var child: TreeNode

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct VariableNode: TreeNode {
    var name: String

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct ConstantNode: TreeNode {
    var value: Value

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}
