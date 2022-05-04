//
//  Equals.swift
//  Melia
//
//  Created by Raphaël Calabro on 04/05/2022.
//

import Foundation

extension Array where Element == TreeNode {
    static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.count != rhs.count {
            return false
        }
        for index in 0 ..< lhs.count {
            if !lhs[index].equals(rhs[index]) {
                return false
            }
        }
        return true
    }
}

extension StateNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? StateNode else {
            return false
        }
        return self.name == other.name
        && self.children == other.children
    }
}

extension GroupNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? GroupNode else {
            return false
        }
        return name == other.name
            && self.arguments == other.arguments
            && self.children == other.children
    }
}

extension InstructionNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? InstructionNode else {
            return false
        }
        return self.name == other.name
            && self.arguments == other.arguments
    }
}

extension ArgumentNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? ArgumentNode else {
            return false
        }
        return self.name == other.name
            && self.value.equals(other)
    }
}

extension SetNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? SetNode else {
            return false
        }
        return self.variable == other.variable
        && self.value.equals(other)
    }
}

extension BinaryOperationNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? BinaryOperationNode else {
            return false
        }
        return self.lhs.equals(other)
            && self.operator == other.operator
            && self.rhs.equals(other)
    }
}

extension UnaryOperationNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? UnaryOperationNode else {
            return false
        }
        return self.operator == other.operator
            && self.value.equals(value)
    }
}

extension BracesNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? BracesNode else {
            return false
        }
        return self.child.equals(other.child)
    }
}

extension VariableNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? VariableNode else {
            return false
        }
        return self.name == other.name
    }
}

extension ConstantNode {
    func equals(_ other: TreeNode) -> Bool {
        guard let other = other as? ConstantNode else {
            return false
        }
        return self.value == other.value
    }
}
