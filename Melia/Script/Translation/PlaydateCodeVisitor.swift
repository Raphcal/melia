//
//  PlaydateCodeVisitor.swift
//  Melia
//
//  Created by Raphaël Calabro on 07/05/2022.
//

import MeliceFramework

extension Array where Element == TreeNode {
    func accept(visitor: PlaydateCodeVisitor) -> [String] {
        return self.flatMap { child in
            child.accept(visitor: visitor)
        }
    }
}

class PlaydateCodeVisitor: TreeNodeVisitor {
    let state: StateNode
    let scriptName: String
    let spriteName: String
    let symbolTable: SymbolTable
    var part = 0

    var statePartStart: String {
        return """
            static void \(state.name)StatePart\(part)(LCDSprite * _Nonnull sprite) {
                struct \(scriptName) *self = (struct \(scriptName) *) playdate->sprite->getUserdata(sprite);


            """
    }

    init(state: StateNode, scriptName: String, spriteName: String, symbolTable: SymbolTable) {
        self.state = state
        self.scriptName = scriptName
        self.spriteName = spriteName
        self.symbolTable = symbolTable
    }

    func visit(from node: StateNode) -> [String] {
        part = 0
        return [statePartStart, node.children.accept(visitor: self).joined(), "}\n\n"]
    }

    func visit(from node: GroupNode) -> [String] {
        part += 1
        var code = [String]()
        code.reserveCapacity(6)
        code.append("""
                // \(node.name)
                self->time = 0;
                playdate->sprite->setUpdateFunction(sprite, &\(state.name)StatePart\(part));

                draw(self, sprite);
            }


            """)
        code.append(statePartStart)

        let duration = node.arguments.first { $0.name == "duration" }?.value ?? ConstantNode(value: .decimal(0))

        code.append("""
                // \(node.name)
                const float duration = \(duration.accept(visitor: self).joined());
                if (self->time < duration) {
                    self->time = MELFloatMin(self->time + DELTA, 1);


            """)
        code.append(contentsOf: node.children.accept(visitor: self).map({ "    " + $0 }))

        part += 1
        code.append("""
                } else {
                    playdate->sprite->setUpdateFunction(sprite, &\(state.name)StatePart\(part));
                }

                draw(self, sprite);
            }


            """)
        code.append(statePartStart)
        return code
    }

    func visit(from node: InstructionNode) -> [String] {
        return ["// \(node.name)\n"]
    }

    func visit(from node: SetNode) -> [String] {
        return [node.variable, " = ", node.value.accept(visitor: self).joined(), ";\n"]
    }

    func visit(from node: BinaryOperationNode) -> [String] {
        let lhsKind = node.lhs.kind(symbolTable: symbolTable)
        let rhsKind = node.lhs.kind(symbolTable: symbolTable)

        let lhs = node.lhs.accept(visitor: self).joined()
        let rhs = node.rhs.accept(visitor: self).joined()

        switch lhsKind {
        case .integer, .decimal:
            switch rhsKind {
            case .integer, .decimal:
                switch node.operator {
                case .add:
                    return [lhs, " + ", rhs]
                case .substract:
                    return [lhs, " - ", rhs]
                case .multiply:
                    return [lhs, " * ", rhs]
                case .divide:
                    return [lhs, " / ", rhs]
                case .and:
                    return [lhs, " && ", rhs]
                case .or:
                    return [lhs, " || ", rhs]
                }
            case .point:
                switch node.operator {
                case .add:
                    return ["MELPointAddValue(", rhs, ", ", lhs, ")"]
                case .substract:
                    return ["MELPointSubstractValue(", rhs, ", ", lhs, ")"]
                case .multiply:
                    return ["MELPointMultiplyByValue(", rhs, ", ", lhs, ")"]
                case .divide:
                    return ["MELPointDivideByValue(", rhs, ", ", lhs, ")"]
                default:
                    break
                }
            default:
                break
            }
        case .point:
            switch rhsKind {
            case .integer, .decimal:
                switch node.operator {
                case .add:
                    return ["MELPointAddValue(", lhs, ", ", rhs, ")"]
                case .substract:
                    return ["MELPointSubstractValue(", lhs, ", ", rhs, ")"]
                case .multiply:
                    return ["MELPointMultiplyByValue(", lhs, ", ", rhs, ")"]
                case .divide:
                    return ["MELPointDivideByValue(", lhs, ", ", rhs, ")"]
                default:
                    break
                }
            case .point:
                switch node.operator {
                case .add:
                    return ["MELPointAdd(", lhs, ", ", rhs, ")"]
                case .substract:
                    return ["MELPointSubstract(", lhs, ", ", rhs, ")"]
                case .multiply:
                    return ["MELPointMultiply(", lhs, ", ", rhs, ")"]
                case .divide:
                    return ["MELPointDivide(", lhs, ", ", rhs, ")"]
                default:
                    break
                }
            default:
                break
            }
        case .boolean:
            if rhsKind == .boolean {
                switch node.operator {
                case .and:
                    return [lhs, " && ", rhs]
                case .or:
                    return [lhs, " || ", rhs]
                default:
                    break
                }
            }
        default:
            break
        }
        return []
    }

    func visit(from node: UnaryOperationNode) -> [String] {
        return ["!", node.value.accept(visitor: self).joined()]
    }

    func visit(from node: BracesNode) -> [String] {
        return ["(", node.child.accept(visitor: self).joined(), ")"]
    }

    func visit(from node: VariableNode) -> [String] {
        return [node.name]
    }

    func visit(from node: ConstantNode) -> [String] {
        switch node.value {
        case let .integer(value):
            return [value.description]
        case let .decimal(value):
            return [value.description]
        case let .point(value):
            return ["MELPointMake(\(value.x), \(value.y))"]
        case let .boolean(value):
            return [value.description]
        case let .string(value):
            return ["\"\(value)\""]
        case let .direction(value):
            switch value {
            case MELDirectionLeft:
                return ["MELDirectionLeft"]
            case MELDirectionRight:
                return ["MELDirectionRight"]
            case MELDirectionUp:
                return ["MELDirectionUp"]
            case MELDirectionDown:
                return ["MELDirectionDown"]
            default:
                break
            }
        case .null:
            return ["NULL"]
        default:
            break
        }
        return []
    }
}
