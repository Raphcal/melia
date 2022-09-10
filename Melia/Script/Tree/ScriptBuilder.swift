//
//  ScriptBuilder.swift
//  Melia
//
//  Created by Raphaël Calabro on 29/04/2022.
//

import Foundation

extension TokenTree {
    var script: Script {
        let builder = ScriptBuilder()

        if let firstState = children.first(where: { $0 is StateNode }) as? StateNode {
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

class ScriptBuilder: TreeNodeVisitor {
    var script = Script(states: [:], initialState: "default", instructions: [])

    func visit(from node: StateNode) -> Void {
        script.states[node.name] = script.instructions.count
        node.children.accept(visitor: self)
        script.instructions.append(GoToCurrentState())
    }

    func visit(from node: ArgumentNode) -> Void {
        node.value.accept(visitor: self)
        script.instructions.append(PushArgument(name: node.name))
    }

    func visit(from node: GroupNode) -> Void {
        let goToGroupStart = GoToGroupStart(groupStart: script.instructions.count)

        node.arguments.accept(visitor: self)
        let groupIndex = script.instructions.count

        switch node.name {
        case "during":
            script.instructions.append(During())
        case "jump":
            script.instructions.append(Jump())
        default:
            print("Group \(node.name) is not supported yet.")
            return
        }
        node.children.accept(visitor: self)
        script.instructions.append(goToGroupStart)

        if var groupStart = script.instructions[groupIndex] as? GroupStart {
            groupStart.whenDoneSetInstructionPointerTo = script.instructions.count
            script.instructions[groupIndex] = groupStart
        }
    }

    func visit(from node: IfNode) -> Void {
        // Non supporté.
    }

    func visit(from node: ElseIfNode) -> Void {
        // Non supporté.
    }

    func visit(from node: ElseNode) -> Void {
        // Non supporté.
    }

    func visit(from node: InstructionNode) -> Void {
        node.arguments.accept(visitor: self)
        switch node.name {
        case "wait":
            break
        case "move":
            script.instructions.append(Move())
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
