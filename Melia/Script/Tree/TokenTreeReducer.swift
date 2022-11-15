//
//  TokenTreeReducer.swift
//  Melia
//
//  Created by Raphaël Calabro on 30/04/2022.
//

import MeliceFramework

/// Optimise l'arbre donné en faisant de l'inlining.
class TokenTreeReducer: TreeNodeVisitor {
    var heap: [String: Value]

    init(heap: [String: Value]) {
        self.heap = heap
    }

    init(sprite: MELSpriteRef) {
        self.heap = ["self": .sprite(sprite)]
    }

    func visit(from node: StateNode) -> TreeNode {
        return StateNode(name: node.name, children: node.children.accept(visitor: self))
    }

    func visit(from node: GroupNode) -> TreeNode {
        return GroupNode(name: node.name,
                         arguments: node.arguments.accept(visitor: self),
                         children: node.children.accept(visitor: self))
    }

    func visit(from node: IfNode) -> TreeNode {
        return node
    }

    func visit(from node: ElseIfNode) -> TreeNode {
        return node
    }

    func visit(from node: ElseNode) -> TreeNode {
        return node
    }

    func visit(from node: ArgumentNode) -> TreeNode {
        return ArgumentNode(name: node.name, value: node.value.accept(visitor: self))
    }

    func visit(from node: InstructionNode) -> TreeNode {
        return node
    }

    func visit(from node: SetNode) -> TreeNode {
        return SetNode(variable: node.variable, value: node.value.accept(visitor: self))
    }
    
    func visit(from node: BinaryOperationNode) -> TreeNode {
        let lhs = node.lhs.accept(visitor: self)
        let rhs = node.rhs.accept(visitor: self)
        if let lhs = lhs as? ConstantNode,
           let rhs = rhs as? ConstantNode {
            return ConstantNode(value: node.operator.instruction.apply(lhs.value, rhs.value))
        } else {
            return BinaryOperationNode(lhs: lhs, operator: node.operator, rhs: rhs)
        }
    }

    func visit(from node: UnaryOperationNode) -> TreeNode {
        let value = node.value.accept(visitor: self)
        if let value = value as? ConstantNode {
            // TODO: Penser à gérer les autres opérateurs unaires.
            return ConstantNode(value: Negative.negative(of: value.value))
        } else {
            return UnaryOperationNode(operator: node.operator, value: value)
        }
    }

    func visit(from node: BracesNode) -> TreeNode {
        let child = node.child.accept(visitor: self)
        if child is ConstantNode {
            return child
        } else {
            return BracesNode(child: child)
        }
    }
    
    func visit(from node: VariableNode) -> TreeNode {
        let path = node.name.components(separatedBy: ".")
        if let value = heap.inlineableValue(at: path) {
            return ConstantNode(value: value)
        } else {
            return node
        }
    }
    
    func visit(from node: ConstantNode) -> TreeNode {
        return node
    }
}


extension TokenTree {
    func reduceByInliningValues(from sprite: MELSpriteRef) -> TokenTree {
        return TokenTree(children: children.accept(visitor: TokenTreeReducer(sprite: sprite)))
    }

    func reduceByInliningValues(from heap: [String: Value]) -> TokenTree {
        return TokenTree(children: children.accept(visitor: TokenTreeReducer(heap: heap)))
    }
}

extension Array where Element == TreeNode {
    func accept(visitor: TokenTreeReducer) -> [TreeNode] {
        return self.map { node in
            node.accept(visitor: visitor)
        }
    }
}

extension Array where Element == ArgumentNode {
    func accept(visitor: TokenTreeReducer) -> [ArgumentNode] {
        return self.map { node in
            node.accept(visitor: visitor) as! ArgumentNode
        }
    }
}
