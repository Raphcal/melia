//
//  ScriptBuilder.swift
//  Melia
//
//  Created by Raphaël Calabro on 29/04/2022.
//

import Foundation

/// Construit une instance de `Script` à partir d'un `TokenTree`.
class ScriptBuilder: TreeNodeVisitor {
    var script = Script(states: [:], initialState: "default", instructions: [])
    var strideCount = 0

    func visit(from node: StateNode) -> Void {
        script.states[node.name] = script.instructions.count
        node.children.accept(visitor: self)

        if node.isConstructor {
            script.instructions.append(Constant(value: .state(script.initialState)))
            script.instructions.append(SetValue(path: ["state"]))
        }
        script.instructions.append(GoToCurrentState())
    }

    func visit(from node: ArgumentNode) -> Void {
        node.value.accept(visitor: self)
        script.instructions.append(PushArgument(name: node.name))
    }

    func visit(from node: GroupNode) -> Void {
        let goToGroupStart = GoToGroupStart(groupStart: script.instructions.count)

        if node.name != "else" {
            node.arguments.accept(visitor: self)
        }
        let groupIndex = script.instructions.count

        switch node.name {
        case "during":
            strideCount = 0
            script.instructions.append(During())
        case "jump":
            script.instructions.append(Jump())
        case "if":
            script.instructions.append(If())
        case "else":
            if let ifIndex = script.instructions.lastIndex(where: { $0 is If }) {
                script.instructions.append(Else())

                var parentIf = script.instructions[ifIndex] as! If
                parentIf.whenDoneSetInstructionPointerTo += 1
                script.instructions[ifIndex] = parentIf
            } else {
                print("Else clause without if.")
                return
            }
        case "while":
            script.instructions.append(While())
        default:
            print("Group \(node.name) is not supported yet.")
            return
        }
        // Ajoute les instructions du contenu du groupe.
        node.children.accept(visitor: self)
        switch node.name {
        case "during", "jump", "while":
            script.instructions.append(goToGroupStart)
        default:
            // Pas de boucle pour if et else
            break
        }

        if groupIndex < script.instructions.count,
           var groupStart = script.instructions[groupIndex] as? GroupStart {
            groupStart.whenDoneSetInstructionPointerTo = script.instructions.count
            script.instructions[groupIndex] = groupStart
        }
    }

    func visit(from node: InstructionNode) -> Void {
        node.arguments.accept(visitor: self)
        switch node.name {
        case "wait":
            break
        case "move":
            script.instructions.append(Move())
        case "new":
            script.instructions.append(NewSprite())
        case "shoot":
            script.instructions.append(Shoot())
        case "shootingStyle":
            script.instructions.append(ShootingStyle())
        case "stride":
            script.instructions.append(Stride(index: strideCount))
            strideCount += 1
        case "angleBetween":
            script.instructions.append(AngleBetween())
        case "distanceBetween":
            script.instructions.append(DistanceBetween())
        case "debug":
            script.instructions.append(Debug())
        default:
            print("Instruction \(node.name) is not supported yet.")
        }
    }

    func visit(from node: SetNode) -> Void {
        node.value.accept(visitor: self)
        script.instructions.append(SetValue(path: node.variable.components(separatedBy: ".")))
    }
    
    func visit(from node: BinaryOperationNode) -> Void {
        node.lhs.accept(visitor: self)
        node.rhs.accept(visitor: self)
        script.instructions.append(node.operator.instruction)
    }
    
    func visit(from node: UnaryOperationNode) -> Void {
        node.value.accept(visitor: self)
        switch node.operator {
        case "-", "!":
            script.instructions.append(Negative())
        case "abs":
            script.instructions.append(Absolute())
        case "cos":
            script.instructions.append(Cosinus())
        case "sin":
            script.instructions.append(Sinus())
        case "sqrt":
            script.instructions.append(SquareRoot())
        case "random":
            script.instructions.append(Random())
        default:
            print("Unary operator \(node.operator) is not supported yet.")
        }
    }
    
    func visit(from node: BracesNode) -> Void {
        node.child.accept(visitor: self)
    }
    
    func visit(from node: VariableNode) -> Void {
        script.instructions.append(Variable(path: node.name.components(separatedBy: ".")))
    }
    
    func visit(from node: ConstantNode) -> Void {
        script.instructions.append(Constant(value: node.value))
    }
}

extension TokenTree {
    var script: Script {
        let builder = ScriptBuilder()

        let firstState = children.first {
            guard let state = $0 as? StateNode else {
                return false
            }
            return state.name != StateNode.constructorName && state.name != StateNode.drawName
        } as? StateNode
        if let firstState {
            builder.script.initialState = firstState.name
        }

        children.accept(visitor: builder)
        return builder.script
    }
}

extension Array where Element == TreeNode {
    func accept(visitor: ScriptBuilder) {
        for node in self {
            node.accept(visitor: visitor)
        }
    }
}

extension Array where Element == ArgumentNode {
    func accept(visitor: ScriptBuilder) {
        visitor.script.instructions.append(ClearArguments())
        for argument in self {
            argument.value.accept(visitor: visitor)
            visitor.script.instructions.append(PushArgument(name: argument.name))
        }
    }
}
