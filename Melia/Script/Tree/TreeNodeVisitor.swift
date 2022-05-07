//
//  TreeNodeVisitor.swift
//  Melia
//
//  Created by Raphaël Calabro on 07/05/2022.
//

import Foundation

protocol TreeNodeVisitor {
    associatedtype Result
    func visit(from node: StateNode) -> Result
    func visit(from node: GroupNode) -> Result
    func visit(from node: IfNode) -> Result
    func visit(from node: ElseIfNode) -> Result
    func visit(from node: ElseNode) -> Result
    func visit(from node: InstructionNode) -> Result
    func visit(from node: ArgumentNode) -> Result
    func visit(from node: SetNode) -> Result
    func visit(from node: BinaryOperationNode) -> Result
    func visit(from node: UnaryOperationNode) -> Result
    func visit(from node: BracesNode) -> Result
    func visit(from node: VariableNode) -> Result
    func visit(from node: ConstantNode) -> Result
}

protocol HasEmptyValue {
    static var empty: Self { get }
}

extension Array: HasEmptyValue {
    static var empty: [Element] {
        return [Element]()
    }
}

extension TreeNodeVisitor where Result : HasEmptyValue {

    func visit(from node: StateNode) -> Result {
        return Result.empty
    }

    func visit(from node: GroupNode) -> Result {
        return Result.empty
    }

    func visit(from node: IfNode) -> Result {
        return Result.empty
    }

    func visit(from node: ElseIfNode) -> Result {
        return Result.empty
    }

    func visit(from node: ElseNode) -> Result {
        return Result.empty
    }

    func visit(from node: InstructionNode) -> Result {
        return Result.empty
    }

    func visit(from node: ArgumentNode) -> Result {
        return Result.empty
    }

    func visit(from node: SetNode) -> Result {
        return Result.empty
    }

    func visit(from node: BinaryOperationNode) -> Result {
        return Result.empty
    }

    func visit(from node: UnaryOperationNode) -> Result {
        return Result.empty
    }

    func visit(from node: BracesNode) -> Result {
        return Result.empty
    }

    func visit(from node: VariableNode) -> Result {
        return Result.empty
    }

    func visit(from node: ConstantNode) -> Result {
        return Result.empty
    }
}
