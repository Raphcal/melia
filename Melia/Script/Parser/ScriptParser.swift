//
//  ScriptParser.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

fileprivate func appendOperator(_ token: FoundToken, instructions: inout [Instruction]) throws {
    let anOperator = try operatorNamed(token.matches[1])
    let lhs = instructions[instructions.count - 2]
    let rhs = instructions[instructions.count - 1]
    if let lhs = lhs as? Constant,
       let rhs = rhs as? Constant {
        instructions.removeLast(2)
        instructions.append(Constant(value: anOperator.apply(lhs.value, rhs.value)))
    } else {
        instructions.append(anOperator)
    }
}

func parse(code: String) throws -> Script {
    var variables = [String: Kind]()
    var statePointers = [String: Int]()
    var instructions = [Instruction]()

    var groups = [Instruction]()
    var indentCount = 0
    var isAfterNewLine = true

    var tokens = [FoundToken]()
    var operators = [FoundToken]()

    try lex(code: code) { current in
        if isAfterNewLine && !current.token.isBlank {
            isAfterNewLine = false
            if indentCount < groups.count {
                for _ in indentCount ..< groups.count {
                    instructions.append(groups.popLast()!)
                }
            }
        }
        switch current.token {
        case .newLine:
            isAfterNewLine = true
            fallthrough
        case .groupEnd, .stateEnd:
            while !operators.isEmpty {
                try appendOperator(operators.removeLast(), instructions: &instructions)
            }
            if tokens.isEmpty {
                return
            }
            switch tokens[0].token {
            case .declareStart:
                variables[tokens[1].matches[1]] = try Kind.named(tokens[3].matches[1])
            case .stateStart:
                let stateName = tokens[1].matches[1]
                statePointers[stateName] = instructions.count
                groups.append(LoadCurrentState())
            case .groupStart:
                switch tokens[0].matches[1] {
                case "during":
                    instructions.append(During())
                case "if":
                    instructions.append(If())
                default:
                    throw LookUpError.badName(tokens[0].matches[1])
                }
            case .setStart:
                instructions.append(SetValue())
            case .instructionStart:
                switch tokens[0].matches[1] {
                case "wait":
                    instructions.append(Wait())
                default:
                    print("Instruction \(tokens[0].matches[1]) is not supported yet")
                    break
                }
            default:
                break
            }
            tokens = []
            indentCount = 0
        case .groupStart:
            groups.append(Jump(to: instructions.count))
        case .indent:
            indentCount = indentCount + 1
        case .valueInt:
            instructions.append(Constant.integer(
                try Int(current.matches[1], format: .number)))
        case .valueDuration:
            let duration = try DurationUnit.named(current.matches[2])
            instructions.append(Constant.duration(
                try Int(current.matches[1], format: .number),
                unit: duration))
        case .valueAnimation:
            instructions.append(Constant.animation(
                try Animation.named(current.matches[1])))
        case .valueDirection:
            instructions.append(Constant.direction(
                try Direction.named(current.matches[1])))
        case .valuePoint:
            instructions.append(Constant.point(Point(
                x: try Int(current.matches[1], format: .number),
                y: try Int(current.matches[2], format: .number))))
        case .valueVariable, .setVariableName:
            instructions.append(Variable(name: current.matches[1]))
        case .addOrSubstract, .multiplyOrDivide:
            if let lastOperator = operators.last, lastOperator.token.priority >= current.token.priority {
                operators.removeLast(1)
                try appendOperator(lastOperator, instructions: &instructions)
            }
            operators.append(current)
        case .instructionArgSeparator:
            // TODO: Voir comment faire un dictionnaire des arguments pour simplifier la création ?
            // Ne semble pas réaliste car ne permet pas l'utilisation d'opérations mathématique comme args
            break
        default:
            tokens.append(current)
        }
    }
    return Script(declare: variables, states: statePointers, instructions: instructions)
}
