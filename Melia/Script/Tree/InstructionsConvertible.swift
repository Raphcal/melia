//
//  Script+TokenTree.swift
//  Melia
//
//  Created by Raphaël Calabro on 29/04/2022.
//

import Foundation

extension TokenTree {
    var script: Script {
        var result = Script(states: [:], initialState: "default", instructions: [])

        if let firstState = children.first(where: { $0 is StateNode }) as? StateNode {
            result.initialState = firstState.name
        }

        children.appendAsInstructions(to: &result)
        return result
    }
}

extension Array where Element == TreeNode {
    func appendAsInstructions(to script: inout Script) {
        for node in self {
            node.appendAsInstructions(to: &script)
        }
    }
}

extension Array where Element == ArgumentNode {
    func appendAsInstructions(to script: inout Script) {
        script.instructions.append(ClearArguments())
        for argument in self {
            argument.value.appendAsInstructions(to: &script)
            script.instructions.append(PushArgument(name: argument.name))
        }
    }
}

extension StateNode {
    func appendAsInstructions(to script: inout Script) {
        script.states[name] = script.instructions.count
        children.appendAsInstructions(to: &script)
        script.instructions.append(GoToCurrentState())
    }
}

extension ArgumentNode {
    func appendAsInstructions(to script: inout Script) {
        value.appendAsInstructions(to: &script)
        script.instructions.append(PushArgument(name: name))
    }
}

extension GroupNode {
    func appendAsInstructions(to script: inout Script) {
        arguments.appendAsInstructions(to: &script)

        let goToGroupStart = GoToGroupStart(groupStart: script.instructions.count)

        switch name {
        case "during":
            script.instructions.append(During())
        default:
            print("Group \(name) is not supported yet.")
            return
        }
        children.appendAsInstructions(to: &script)
        script.instructions.append(goToGroupStart)

        if var groupStart = script.instructions[goToGroupStart.groupStart] as? GroupStart {
            groupStart.whenDoneSetInstructionPointerTo = script.instructions.count
            script.instructions[goToGroupStart.groupStart] = groupStart
        }
    }
}

extension InstructionNode {
    func appendAsInstructions(to script: inout Script) {
        arguments.appendAsInstructions(to: &script)
        switch name {
        case "wait":
            break
        default:
            print("Instruction \(name) is not supported yet.")
        }
    }
}

extension SetNode {
    func appendAsInstructions(to script: inout Script) {
        value.appendAsInstructions(to: &script)
        script.instructions.append(SetValue(path: variable.components(separatedBy: ".")))
    }
}

extension OperatorKind {
    var instruction: Operator {
        switch self {
        case .add:
            return Add()
        case .substract:
            return Substract()
        case .multiply:
            return Multiply()
        case .divide:
            return Divide()
        case .and:
            return And()
        case .or:
            return Or()
        }
    }
}

extension BinaryOperationNode {
    func appendAsInstructions(to script: inout Script) {
        lhs.appendAsInstructions(to: &script)
        rhs.appendAsInstructions(to: &script)
        script.instructions.append(self.operator.instruction)
    }
}

extension UnaryOperationNode {
    func appendAsInstructions(to script: inout Script) {
        value.appendAsInstructions(to: &script)
        switch self.operator {
        case "-", "!":
            script.instructions.append(Negative())
        default:
            print("Unary operator \(self.operator) is not supported yet.")
        }
    }
}

extension BracesNode {
    func appendAsInstructions(to script: inout Script) {
        child.appendAsInstructions(to: &script)
    }
}

extension ConstantNode {
    func appendAsInstructions(to script: inout Script) {
        script.instructions.append(Constant(value: value))
    }
}

extension VariableNode {
    func appendAsInstructions(to script: inout Script) {
        script.instructions.append(Variable(path: name.components(separatedBy: ".")))
    }
}
