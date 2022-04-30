//
//  Inliner.swift
//  Melia
//
//  Created by Raphaël Calabro on 30/04/2022.
//

import MeliceFramework

extension TokenTree {
    func reduceByInliningValues(from sprite: MELSpriteRef) -> TokenTree {
        return reduceByInliningValues(from: ["self": .sprite(sprite)])
    }

    func reduceByInliningValues(from heap: [String: Value]) -> TokenTree {
        return TokenTree(children: children.map({ $0.reduceByInliningValues(from: heap) }))
    }
}

extension StateNode {
    func reduceByInliningValues(from heap: [String : Value]) -> TreeNode {
        return StateNode(name: name, children: children.map { $0.reduceByInliningValues(from: heap) })
    }
}

extension GroupNode {
    func reduceByInliningValues(from heap: [String : Value]) -> TreeNode {
        return GroupNode(name: name,
                         arguments: arguments.map {
            $0.reduceByInliningValues(from: heap) as! ArgumentNode
        },
                         children: children.map {
            $0.reduceByInliningValues(from: heap)
        })
    }
}

extension ArgumentNode {
    func reduceByInliningValues(from heap: [String : Value]) -> TreeNode {
        return ArgumentNode(name: name, value: value.reduceByInliningValues(from: heap))
    }
}

extension SetNode {
    func reduceByInliningValues(from heap: [String : Value]) -> TreeNode {
        return SetNode(variable: variable, value: value.reduceByInliningValues(from: heap))
    }
}

extension BinaryOperationNode {
    func reduceByInliningValues(from heap: [String: Value]) -> TreeNode {
        let lhs = lhs.reduceByInliningValues(from: heap)
        let rhs = rhs.reduceByInliningValues(from: heap)
        if let lhs = lhs as? ConstantNode,
           let rhs = rhs as? ConstantNode {
            return ConstantNode(value: self.operator.instruction.apply(lhs.value, rhs.value))
        } else {
            return BinaryOperationNode(lhs: lhs, operator: self.operator, rhs: rhs)
        }
    }
}

extension UnaryOperationNode {
    func reduceByInliningValues(from heap: [String : Value]) -> TreeNode {
        let value = value.reduceByInliningValues(from: heap)
        if let value = value as? ConstantNode {
            // TODO: Penser à gérer les autres opérateurs unaires.
            return ConstantNode(value: Negative.negative(of: value.value))
        } else {
            return UnaryOperationNode(operator: self.operator, value: value)
        }
    }
}

extension BracesNode {
    func reduceByInliningValues(from heap: [String : Value]) -> TreeNode {
        let child = child.reduceByInliningValues(from: heap)
        if child is ConstantNode {
            return child
        } else {
            return BracesNode(child: child)
        }
    }
}

extension VariableNode {
    func reduceByInliningValues(from heap: [String: Value]) -> TreeNode {
        let path = name.components(separatedBy: ".")
        let value = heap.value(at: path)
        switch value {
        case .integer(_), .decimal(_), .point(_), .boolean(_), .string(_), .direction(_):
            return ConstantNode(value: value)
        default:
            return self
        }
    }
}
