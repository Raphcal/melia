//
//  TreeNode.swift
//  Melia
//
//  Created by Raphaël Calabro on 26/04/2022.
//

import Foundation

struct TokenTree {
    var children: [TreeNode]
}

protocol TreeNode {
    // Vide
}

struct StateNode: TreeNode {
    var name: String
    var children: [TreeNode]
}

struct GroupNode: TreeNode {
    var name: String
    var arguments: [ArgumentNode]
    var children: [TreeNode]
}

// TODO: Voir s'il faut ajouter un IfNode
struct IfNode: TreeNode {
    var condition: TreeNode
    var children: [TreeNode]
    var elseIfs: [ElseIfNode]
    var `else`: [ElseNode]
}

struct ElseIfNode: TreeNode {
    var condition: TreeNode
    var children: [TreeNode]
}

struct ElseNode: TreeNode {
    var children: [TreeNode]
}

struct InstructionNode: TreeNode {
    var name: String
    var arguments: [ArgumentNode]
}

struct ArgumentNode: TreeNode {
    var name: String
    var value: TreeNode
}

struct SetNode: TreeNode {
    var variable: String
    var value: TreeNode
}

struct BinaryOperationNode: TreeNode {
    var lhs: TreeNode
    var `operator`: OperatorKind
    var rhs: TreeNode
}

struct UnaryOperationNode: TreeNode {
    var `operator`: String
    var value: TreeNode
}

struct BracesNode: TreeNode {
    var child: TreeNode
}

struct VariableNode: TreeNode {
    var name: String
}

struct ConstantNode: TreeNode {
    var value: Value
}
