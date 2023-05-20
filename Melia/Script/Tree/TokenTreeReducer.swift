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

    convenience init(sprite: MELSpriteRef, symbolTable: SymbolTable) {
        var heap: [String: Value] = ["self": .sprite(sprite)]
        heap.reserveCapacity(symbolTable.constants.count + 1)
        for (key, constant) in symbolTable.constants {
            heap[key] = constant.value
        }
        self.init(heap: heap)
    }

    func visit(from node: StateNode) -> TreeNode {
        return StateNode(name: node.name, children: node.children.accept(visitor: self))
    }

    func visit(from node: GroupNode) -> TreeNode {
        return GroupNode(name: node.name,
                         arguments: node.arguments.accept(visitor: self),
                         children: node.children.accept(visitor: self))
    }

    func visit(from node: ArgumentNode) -> TreeNode {
        return ArgumentNode(name: node.name, value: node.value.accept(visitor: self))
    }

    func visit(from node: InstructionNode) -> TreeNode {
        var newNode = node
        if newNode.name == "stride" {
            if let fromIndex = node.arguments.firstIndex(where: { $0.name == Stride.fromArgument }) {
                newNode.arguments[fromIndex].value = node.arguments[fromIndex].value.accept(visitor: self)
            }
            if let toIndex = node.arguments.firstIndex(where: { $0.name == Stride.toArgument }) {
                newNode.arguments[toIndex].value = node.arguments[toIndex].value.accept(visitor: self)
            }
            if let progressIndex = node.arguments.firstIndex(where: { $0.name == Stride.progressArgument }) {
                newNode.arguments[progressIndex].value = node.arguments[progressIndex].value.accept(visitor: self)
            }
        }
        return newNode
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
        } else if let lhs = lhs as? ConstantNode,
                  let rhs = rhs as? VariableNode {
            if case let .integer(value) = lhs.value, value == 0 {
                switch node.operator {
                case .add:
                    return rhs
                case .substract:
                    return UnaryOperationNode(operator: "-", value: rhs)
                case .multiply, .divide, .modulo:
                    return ConstantNode(value: .integer(0))
                default:
                    break
                }
            } else if case let .decimal(value) = lhs.value, value == 0.0 {
                switch node.operator {
                case .add:
                    return rhs
                case .substract:
                    return UnaryOperationNode(operator: "-", value: rhs)
                case .multiply, .divide, .modulo:
                    return ConstantNode(value: .integer(0))
                default:
                    break
                }
            } else if case let .integer(value) = lhs.value, value == 1,
                      node.operator == .multiply {
                return rhs
            } else if case let .decimal(value) = lhs.value, value == 1.0,
                      node.operator == .multiply {
                return rhs
            }
        } else if let lhs = lhs as? VariableNode,
                  let rhs = rhs as? ConstantNode {
            if case let .integer(value) = rhs.value, value == 0 {
                switch node.operator {
                case .add, .substract:
                    return lhs
                case .multiply:
                    return ConstantNode(value: .integer(0))
                case .divide:
                    return ConstantNode(value: .null)
                default:
                    break
                }
            } else if case let .decimal(value) = rhs.value, value == 0.0 {
                switch node.operator {
                case .add, .substract:
                    return lhs
                case .multiply:
                    return ConstantNode(value: .integer(0))
                case .divide:
                    return ConstantNode(value: .null)
                default:
                    break
                }
            } else if case let .integer(value) = rhs.value, value == 1,
                      node.operator == .multiply || node.operator == .divide {
                return lhs
            } else if case let .decimal(value) = rhs.value, value == 1.0,
                      node.operator == .multiply || node.operator == .divide {
                return lhs
            }
        } else if let lhs = lhs as? VariableNode,
                  let rhs = rhs as? VariableNode,
                  lhs.name == rhs.name && node.operator == .substract {
            return ConstantNode(value: .integer(0))
        }
        /// Simplification de `(2 + (2 + x))` en `(4 + x)`.
        else if let lhs = lhs as? ConstantNode,
                  let rhs = rhs as? BinaryOperationNode,
                  let rhsLhs = rhs.lhs as? ConstantNode,
                  node.operator == rhs.operator {
            return BinaryOperationNode(lhs: ConstantNode(value: node.operator.instruction.apply(lhs.value, rhsLhs.value)), operator: node.operator, rhs: rhs.rhs)
        }
        /// Simplification de `(2 + (x + 2))` en `(4 + x)`.
        else if let lhs = lhs as? ConstantNode,
                  let rhs = rhs as? BinaryOperationNode,
                  let rhsRhs = rhs.rhs as? ConstantNode,
                  node.operator == rhs.operator {
            return BinaryOperationNode(lhs: ConstantNode(value: node.operator.instruction.apply(lhs.value, rhsRhs.value)), operator: node.operator, rhs: rhs.lhs)
        }
        /// Simplification de `((2 + x) + 2)` en `(4 + x)`.
        else if let lhs = lhs as? BinaryOperationNode,
                  let rhs = rhs as? ConstantNode,
                  let lhsLhs = lhs.lhs as? ConstantNode,
                  node.operator == lhs.operator {
            return BinaryOperationNode(lhs: ConstantNode(value: node.operator.instruction.apply(rhs.value, lhsLhs.value)), operator: node.operator, rhs: lhs.rhs)
        }
        /// Simplification de `((x + 2) + 2)` en `(x + 4)`.
        else if let lhs = lhs as? BinaryOperationNode,
                  let rhs = rhs as? ConstantNode,
                  let lhsRhs = lhs.rhs as? ConstantNode,
                  node.operator == lhs.operator {
            return BinaryOperationNode(lhs: lhs.rhs, operator: node.operator, rhs: ConstantNode(value: node.operator.instruction.apply(rhs.value, lhsRhs.value)))
        }
        /// Simplification de `(x - (x + 2))` en `(-2)`.
        else if let lhs = lhs as? VariableNode,
                  let rhs = rhs as? BinaryOperationNode,
                  let rhsLhs = rhs.lhs as? VariableNode,
                node.operator == .substract,
                lhs.name == rhsLhs.name,
                rhs.operator == .add || rhs.operator == .substract {
            return UnaryOperationNode(operator: "-", value: rhs.rhs).accept(visitor: self)
        }
        /// Simplification de `(x - (2 + x))` en `(-2)`.
        else if let lhs = lhs as? VariableNode,
                  let rhs = rhs as? BinaryOperationNode,
                  let rhsRhs = rhs.rhs as? VariableNode,
                node.operator == .substract,
                lhs.name == rhsRhs.name,
                rhs.operator == .add {
            return UnaryOperationNode(operator: "-", value: rhs.lhs).accept(visitor: self)
        }
        /// Simplification de `((x + 2) - x)` en `(2)`.
        else if let lhs = lhs as? BinaryOperationNode,
                  let rhs = rhs as? VariableNode,
                  let lhsLhs = lhs.lhs as? VariableNode,
                node.operator == .substract,
                rhs.name == lhsLhs.name,
                lhs.operator == .add || lhs.operator == .substract {
            return lhs.rhs
        }
        /// Simplification de `((2 + x) - x)` en `(2)`.
        else if let lhs = lhs as? BinaryOperationNode,
                  let rhs = rhs as? VariableNode,
                  let lhsRhs = lhs.rhs as? VariableNode,
                node.operator == .substract,
                rhs.name == lhsRhs.name,
                lhs.operator == .add {
            return lhs.lhs
        }
        /// Simplification de `((x +- 5) - (x +- 3))` en `(2)`
        else if let lhs = lhs as? BinaryOperationNode,
                let rhs = rhs as? BinaryOperationNode,
                let lhsLhs = lhs.lhs as? VariableNode,
                let rhsLhs = rhs.lhs as? VariableNode,
                node.operator == .substract,
                lhs.operator == .add || lhs.operator == .substract,
                rhs.operator == .add || rhs.operator == .substract,
                lhsLhs.name == rhsLhs.name {
            return BinaryOperationNode(lhs: BinaryOperationNode(lhs: ConstantNode(value: .integer(0)), operator: lhs.operator, rhs: lhs.rhs), operator: node.operator, rhs: BinaryOperationNode(lhs: ConstantNode(value: .integer(0)), operator: rhs.operator, rhs: rhs.rhs)).accept(visitor: self)
        }
        /// Simplification de `((5 + x) - (x +- 3))` en `(2)`
        else if let lhs = lhs as? BinaryOperationNode,
                let rhs = rhs as? BinaryOperationNode,
                let lhsRhs = lhs.rhs as? VariableNode,
                let rhsLhs = rhs.lhs as? VariableNode,
                node.operator == .substract,
                lhs.operator == .add,
                rhs.operator == .add || rhs.operator == .substract,
                lhsRhs.name == rhsLhs.name {
            return BinaryOperationNode(lhs: lhs.lhs, operator: node.operator, rhs: BinaryOperationNode(lhs: ConstantNode(value: .integer(0)), operator: rhs.operator, rhs: rhs.rhs)).accept(visitor: self)
        }
        /// Simplification de `((5 + x) - (3 + x))` en `(2)`
        /// Simplification de `((5 - x) - (3 - x))` en `(2)`
        else if let lhs = lhs as? BinaryOperationNode,
                let rhs = rhs as? BinaryOperationNode,
                let lhsRhs = lhs.rhs as? VariableNode,
                let rhsRhs = rhs.rhs as? VariableNode,
                node.operator == .substract,
                lhs.operator == .add || lhs.operator == .substract,
                lhs.operator == rhs.operator,
                lhsRhs.name == rhsRhs.name {
            return BinaryOperationNode(lhs: lhs.lhs, operator: node.operator, rhs: rhs.lhs).accept(visitor: self)
        }
        /// Simplification de `((x +- 5) + (3 - x))` en `(8)`
        else if let lhs = lhs as? BinaryOperationNode,
                let rhs = rhs as? BinaryOperationNode,
                let lhsLhs = lhs.lhs as? VariableNode,
                let rhsRhs = rhs.rhs as? VariableNode,
                node.operator == .add,
                lhs.operator == .add || lhs.operator == .substract,
                rhs.operator == .substract,
                lhsLhs.name == rhsRhs.name {
            return BinaryOperationNode(lhs: BinaryOperationNode(lhs: ConstantNode(value: .integer(0)), operator: lhs.operator, rhs: lhs.rhs), operator: node.operator, rhs: rhs.lhs).accept(visitor: self)
        }
        /// Simplification de `((5 + x) + (3 - x))` en `(8)`
        /// Simplification de `((5 - x) + (3 + x))` en `(8)`
        else if let lhs = lhs as? BinaryOperationNode,
                let rhs = rhs as? BinaryOperationNode,
                let lhsRhs = lhs.rhs as? VariableNode,
                let rhsRhs = rhs.rhs as? VariableNode,
                node.operator == .add,
                (lhs.operator == .add && rhs.operator == .substract) || (lhs.operator == .substract && rhs.operator == .add),
                lhsRhs.name == rhsRhs.name {
            return BinaryOperationNode(lhs: lhs.lhs, operator: node.operator, rhs: rhs.lhs).accept(visitor: self)
        }
        return BinaryOperationNode(lhs: lhs, operator: node.operator, rhs: rhs)
    }

    func visit(from node: UnaryOperationNode) -> TreeNode {
        let value = node.value.accept(visitor: self)
        if let value = value as? ConstantNode, node.operator == "-" || node.operator == "!" {
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
    func reduceByInliningValues(from sprite: MELSpriteRef, symbolTable: SymbolTable) -> TokenTree {
        return TokenTree(children: children.accept(visitor: TokenTreeReducer(sprite: sprite, symbolTable: symbolTable)))
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
