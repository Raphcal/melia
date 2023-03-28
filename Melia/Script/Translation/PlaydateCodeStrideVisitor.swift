//
//  PlaydateCodeStrideVisitor.swift
//  Melia
//
//  Created by Raphaël Calabro on 28/03/2023.
//

import Foundation

struct PlaydateCodeStride {
    var fromName: String
    var fromValue: TreeNode
    var toName: String
    var toValue: TreeNode
    var isConstant: Bool
    var operation: BinaryOperationNode
}

class PlaydateCodeStrideVisitor: TreeNodeVisitor {
    var symbolTable: SymbolTable
    var strideCount = 0

    init(symbolTable: SymbolTable) {
        self.symbolTable = symbolTable
    }

    func visit(from node: InstructionNode) -> [PlaydateCodeStride] {
        if node.name == "stride" {
            let from = node.arguments.first { $0.name == Stride.fromArgument }?.value ?? ConstantNode(value: .decimal(0))
            let to = node.arguments.first { $0.name == Stride.toArgument }?.value ?? ConstantNode(value: .decimal(0))
            let kind = node.kind(symbolTable: symbolTable)
            let kindCapitalized = String(describing: kind).capitalized
            let fromOperand = from is ConstantNode ? from : VariableNode(name: "stride\(kindCapitalized)From\(strideCount)")
            let toOperand = to is ConstantNode ? to : VariableNode(name: "stride\(kindCapitalized)To\(strideCount)")
            let operation = BinaryOperationNode(lhs: fromOperand, operator: .add, rhs: BinaryOperationNode(lhs: BracesNode(child: BinaryOperationNode(lhs: toOperand, operator: .substract, rhs: fromOperand)), operator: .multiply, rhs: VariableNode(name: "progress")))
            let stride = PlaydateCodeStride(fromName: "self->stride\(kindCapitalized)From\(strideCount)", fromValue: from, toName: "self->stride\(kindCapitalized)To\(strideCount)", toValue: to, isConstant: from is ConstantNode && to is ConstantNode, operation: operation)
            strideCount += 1
            return [stride]
        }
        return []
    }

    func visit(from node: GroupNode) -> [PlaydateCodeStride] {
        return node.children.accept(visitor: self)
    }

    func visit(from node: SetNode) -> [PlaydateCodeStride] {
        return node.value.accept(visitor: self)
    }

    func visit(from node: UnaryOperationNode) -> [PlaydateCodeStride] {
        return node.value.accept(visitor: self)
    }

    func visit(from node: BinaryOperationNode) -> [PlaydateCodeStride] {
        let lhs = node.lhs.accept(visitor: self)
        let rhs = node.rhs.accept(visitor: self)
        return lhs + rhs
    }

    func visit(from node: BracesNode) -> [PlaydateCodeStride] {
        return node.child.accept(visitor: self)
    }
}

fileprivate extension Array where Element == TreeNode {
    func accept(visitor: PlaydateCodeStrideVisitor) -> [PlaydateCodeStride] {
        return self.flatMap { child in
            child.accept(visitor: visitor)
        }
    }
}
