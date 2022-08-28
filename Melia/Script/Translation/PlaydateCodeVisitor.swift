//
//  PlaydateCodeVisitor.swift
//  Melia
//
//  Created by Raphaël Calabro on 07/05/2022.
//

import MeliceFramework

extension Array where Element == TreeNode {
    func accept(visitor: PlaydateCodeVisitor) -> [String] {
        return self.map { child in
            child.accept(visitor: visitor).joined()
        }
    }
}

// Translate a TreeNode to C code.
class PlaydateCodeVisitor: TreeNodeVisitor {
    let state: StateNode
    let scriptName: String
    let spriteName: String
    var symbolTable: SymbolTable
    var part = 0

    var statePartStart: String {
        return """
            static void \(state.name)StatePart\(part)(LCDSprite * _Nonnull sprite) {
                struct \(scriptName) *self = (struct \(scriptName) *) playdate->sprite->getUserdata(sprite);


            """
    }

    var stateEnd: String {
        if symbolTable.states.count > 1 {
            return """
                    goToCurrentState(sprite);
                    draw(self, sprite);
                }

                
                """
        } else {
            return """
                    playdate->sprite->setUpdateFunction(sprite, &\(state.name)StatePart0);
                    draw(self, sprite);
                }

                
                """
        }
    }

    init(state: StateNode, scriptName: String, spriteName: String, symbolTable: SymbolTable) {
        self.state = state
        self.scriptName = scriptName
        self.spriteName = spriteName
        self.symbolTable = symbolTable
    }

    func visit(from node: StateNode) -> [String] {
        part = 0
        return [
            statePartStart,
            node.children.accept(visitor: self).joined(),
            stateEnd]
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
                    const float newTime = MELFloatMin(self->time + DELTA, duration);\n
            """)

        // TODO: Ne pas générer "progress" s'il n'est pas utilisé.
        var easeInOut = false
        if let easeArgument = node.arguments.first(where: { $0.name == "ease" })?.value as? ConstantNode,
           case let .boolean(value) = easeArgument.value {
            easeInOut = value
        }
        code.append("        const float progress = \(easeInOut ? "MELEaseInOut(0, duration, newTime)" : "newTime / duration");\n")

        code.append("        self->time = newTime;\n\n")

        symbolTable.localVariables["progress"] = .decimal
        code.append(contentsOf: node.children.accept(visitor: self).map({ "    " + $0 }))
        symbolTable.localVariables.removeValue(forKey: "progress")

        // TODO: Voir comment intégrer les étapes d'après during dans le else après setUpdateFunction.
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
        return ["    // \(node.name)\n"]
    }

    func visit(from node: SetNode) -> [String] {
        let kind = node.value.kind(symbolTable: symbolTable)
        let assignedValue = node.value.accept(visitor: self).joined()

        var variable = ""
        let path = node.variable.components(separatedBy: ".")
        if !symbolTable.isLocalvariable(node.variable) && path[0] != "self" {
            variable = "self->"
        }
        variable += path[0]

        if kind == .animationName {
            return ["    AnimationNameSetAnimation(", assignedValue, ", ", variable, "->super.direction, ", variable, "->super.definition, &", variable, "->super.animationName, &", variable, "->super.animation);\n"]
        } else {
            var value = symbolTable.variables[path[0]] ?? .null
            for property in path[1...] {
                switch value {
                case .sprite:
                    switch property {
                    case "center":
                        variable += "->super.frame.origin"
                    case "frame", "animation", "direction":
                        variable += "->super.\(property)"
                    default:
                        variable += "->\(property)"
                    }
                default:
                    variable += ".\(property)"
                }
                value = value.kind(for: property)
            }
            return ["    ", variable, " = ", assignedValue, ";\n"]
        }
    }

    func visit(from node: BinaryOperationNode) -> [String] {
        let lhsKind = node.lhs.kind(symbolTable: symbolTable)
        let rhsKind = node.rhs.kind(symbolTable: symbolTable)

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
        return [node.operator, node.value.accept(visitor: self).joined()]
    }

    func visit(from node: BracesNode) -> [String] {
        return ["(", node.child.accept(visitor: self).joined(), ")"]
    }

    func visit(from node: VariableNode) -> [String] {
        var translatedName = ""
        let path = node.name.components(separatedBy: ".")
        if !symbolTable.isLocalvariable(node.name) && path[0] != "self" {
            translatedName = "self->"
        }
        translatedName += path[0]
        var value = symbolTable.variables[path[0]] ?? .null
        for property in path[1...] {
            switch value {
            case .sprite:
                switch property {
                case "center":
                    translatedName += "->super.frame.origin"
                case "frame", "animation", "direction":
                    translatedName += "->super.\(property)"
                default:
                    translatedName += "->\(property)"
                }
            case .direction:
                switch property {
                case "animationDirection":
                    translatedName = "MELDirectionAnimationDirection[\(translatedName)]"
                case "angle":
                    translatedName = "MELDirectionAngles[\(translatedName)]"
                case "axe":
                    translatedName = "MELDirectionAxe[\(translatedName)]"
                case "flip":
                    translatedName = "MELDirectionFlip[\(translatedName)]"
                case "reverse":
                    translatedName = "MELDirectionReverses[\(translatedName)]"
                case "value":
                    translatedName = "MELDirectionValues[\(translatedName)]"
                default:
                    break
                }
            default:
                translatedName += ".\(property)"
            }
            value = value.kind(for: property)
        }
        return [translatedName]
    }

    func visit(from node: ConstantNode) -> [String] {
        switch node.value {
        case let .integer(value):
            return [value.description]
        case let .decimal(value):
            return [value.description, "f"]
        case let .point(value):
            return ["MELPointMake(\(value.x)f, \(value.y)f)"]
        case let .boolean(value):
            return [value.description]
        case let .string(value):
            return ["\"", value, "\""]
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
        case let .animationName(value):
            return ["AnimationName\(value.capitalized)"]
        case .null:
            return ["NULL"]
        default:
            break
        }
        return []
    }
}
