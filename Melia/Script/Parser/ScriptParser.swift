//
//  ScriptParser.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

fileprivate func append(operator token: FoundToken, instructions: inout [Instruction]) throws {
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

fileprivate func onGroupEnd(groups: inout [Instruction], instructions: inout [Instruction], indentCount: Int = 0) {
    if indentCount < groups.count {
        for _ in indentCount ..< groups.count {
            let gotoGroupStart = groups.removeLast()
            instructions.append(gotoGroupStart)
            if let gotoGroupStart = gotoGroupStart as? GoToGroupStart,
               var groupStart = instructions[gotoGroupStart.groupStart] as? GroupStart {
                groupStart.whenDoneSetInstructionPointerTo = instructions.count
                instructions[gotoGroupStart.groupStart] = groupStart
            }
        }
    }
}

func parse(code: String) throws -> Script {
    var statePointers = [String: Int]()
    var instructions = [Instruction]()
    var initialState: String?

    var groups = [Instruction]()
    var indentCount = 0
    var isAfterNewLine = true

    var tokens = [FoundToken]()
    var tokenStack = [FoundToken]()
    var operators = [FoundToken]()

    try lex(code: code) { current in
        tokens.append(current)

        if isAfterNewLine && !current.token.isBlank {
            isAfterNewLine = false
            onGroupEnd(groups: &groups, instructions: &instructions, indentCount: indentCount)
        }
        switch current.token {
        case .newLine:
            isAfterNewLine = true
            fallthrough
        case .groupEnd, .stateEnd:
            while !operators.isEmpty {
                try append(operator: operators.removeLast(), instructions: &instructions)
            }
            if tokenStack.isEmpty {
                return
            }
            if tokenStack.last!.token == .instructionArgument {
                instructions.append(PushArgument(name: tokenStack.last!.matches[1]))
            }
            switch tokenStack[0].token {
            case .stateStart:
                let stateName = tokenStack[1].matches[1]
                statePointers[stateName] = instructions.count
                groups.append(GoToCurrentState())
                if initialState == nil {
                    initialState = stateName
                }
            case .groupStart:
                switch tokenStack[0].matches[1] {
                case "during":
                    // TODO: Gérer les arguments
                    groups.append(GoToGroupStart(groupStart: instructions.count))
                    instructions.append(During())
                default:
                    throw LookUpError.badName(tokenStack[0].matches[1])
                }
            case .setStart:
                instructions.append(SetValue(path: tokenStack[1].matches[1].components(separatedBy: ".")))
            case .instructionStart:
                if let last = tokenStack.last, last.token == .instructionArgument {
                    instructions.append(PushArgument(name: last.matches[1]))
                }
                switch tokenStack[0].matches[1] {
                case "wait":
                    instructions.append(Wait())
                default:
                    print("Instruction \(tokenStack[0].matches[1]) is not supported yet")
                    break
                }
            default:
                break
            }
            tokenStack = []
            indentCount = 0
        case .groupStart:
            tokenStack.append(current)
            instructions.append(ClearArguments())
            switch current.matches[1] {
            case "during":
                tokenStack.append(FoundToken(token: .instructionArgument, matches: ["", "duration"], range: Range(0...0)))
            default:
                break
            }
        case .indent:
            indentCount = indentCount + 1
        case .valueInt:
            instructions.append(Constant(value: .integer(
                Int32(current.matches[1]) ?? 0
            )))
        case .valueDecimal:
            instructions.append(Constant(value: .decimal(
                Float(current.matches[1]) ?? 0
            )))
        case .valueDuration:
            let duration = try DurationUnit.named(current.matches[2])
            instructions.append(Constant(value: .decimal(
                duration.toTimeInterval(
                    Int32(current.matches[1]) ?? 0
                )
            )))
        case .valueBoolean:
            instructions.append(Constant(value: .boolean(
                current.matches[1] == "true"
            )))
        case .valueAnimation:
            instructions.append(Constant(value: .string(
                current.matches[1]
            )))
        case .valueString:
            instructions.append(Constant(value: .string(
                current.matches[1]
                    .replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\\\", with: "\\")
            )))
        case .valueDirection:
            instructions.append(Constant(value: .direction(
                try MELDirection.named(current.matches[1])
            )))
        case .valuePoint:
            let intPoint = MELIntPoint(
                x: Int32(current.matches[1]) ?? 0,
                y: Int32(current.matches[2]) ?? 0)
            instructions.append(Constant(value : .point(MELPoint(intPoint))))
        case .valueVariable:
            instructions.append(Variable(
                path: current.matches[1]
                    .components(separatedBy: ".")
            ))
        case .addOrSubstract, .multiplyOrDivide, .andOrOr:
            if let lastOperator = operators.last, lastOperator.token.priority >= current.token.priority {
                operators.removeLast(1)
                try append(operator: lastOperator, instructions: &instructions)
            }
            operators.append(current)
        case .instructionArgument:
            if let last = tokenStack.last, last.token == .instructionArgument {
                instructions.append(PushArgument(name: last.matches[1]))
            } else if let last = tokenStack.last, last.token == .instructionStart {
                instructions.append(ClearArguments())
            }
            tokenStack.append(current)
        default:
            tokenStack.append(current)
        }
    }
    onGroupEnd(groups: &groups, instructions: &instructions)
    return Script(states: statePointers, initialState: initialState ?? "default", instructions: instructions, tokens: tokens)
}

extension String {
    var script: Script {
        let script = try? parse(code: self)
        return script ?? .empty
    }
}
