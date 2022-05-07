//
//  TreeNode.swift
//  Melia
//
//  Created by Raphaël Calabro on 26/04/2022.
//

import Foundation

struct TokenTree: Equatable {
    var children: [TreeNode]

    static func == (lhs: TokenTree, rhs: TokenTree) -> Bool {
        return lhs.children == rhs.children
    }
}

protocol TreeNode {
    func appendAsInstructions(to script: inout Script)
    func reduceByInliningValues(from heap: [String: Value]) -> TreeNode
    func kind(symbolTable: SymbolTable) -> ValueKind
    func fill(symbolTable: inout SymbolTable)
    func equals(_ other: TreeNode) -> Bool
    func accept<V: TreeNodeVisitor>(visitor: V) -> V.Result
}

extension TreeNode {
    func appendAsInstructions(to script: inout Script) {
        // Aucune action.
    }
    func reduceByInliningValues(from heap: [String: Value]) -> TreeNode {
        return self
    }
    func kind(symbolTable: SymbolTable) -> ValueKind {
        return .null
    }
    func fill(symbolTable: inout SymbolTable) {
        // Aucune action.
    }
    func equals(_ other: TreeNode) -> Bool {
        return false
    }
}

struct StateNode: TreeNode {
    var name: String
    var children: [TreeNode]

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

// TODO: Voir s'il faut ajouter un IfNode
struct IfNode: TreeNode {
    var condition: TreeNode
    var children: [TreeNode]
    var `else`: TreeNode?

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct ElseIfNode: TreeNode {
    var condition: TreeNode
    var children: [TreeNode]
    var `else`: TreeNode?

    func accept<V>(visitor: V) -> V.Result where V : TreeNodeVisitor {
        return visitor.visit(from: self)
    }
}

struct ElseNode: TreeNode {
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
