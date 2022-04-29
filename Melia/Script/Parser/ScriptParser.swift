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

        guard current.token != .comment
        else {
            return
        }

        if isAfterNewLine && !current.token.isBlank {
            isAfterNewLine = false
            onGroupEnd(groups: &groups, instructions: &instructions, indentCount: indentCount)
        }
        switch current.token {
        case .state:
            while !operators.isEmpty {
                try append(operator: operators.removeLast(), instructions: &instructions)
            }
            let stateName = current.matches[1]
            statePointers[stateName] = instructions.count
            groups.append(GoToCurrentState())
            if initialState == nil {
                initialState = stateName
            }
        case .newLine:
            isAfterNewLine = true
            fallthrough
        case .groupEnd:
            while !operators.isEmpty {
                try append(operator: operators.removeLast(), instructions: &instructions)
            }
            if tokenStack.isEmpty {
                indentCount = 0
                return
            }
            if tokenStack.last!.token == .instructionArgument {
                instructions.append(PushArgument(name: tokenStack.last!.matches[1]))
            }
            switch tokenStack[0].token {
            case .groupStart:
                switch tokenStack[0].matches[1] {
                case "during":
                    groups.append(GoToGroupStart(groupStart: instructions.count))
                    instructions.append(During())
                default:
                    throw LookUpError.badName(tokenStack[0].matches[1])
                }
            case .setStart:
                instructions.append(SetValue(path: tokenStack[0].matches[1].components(separatedBy: ".")))
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
        case .valueInt, .valueDecimal, .valueDuration, .valueBoolean, .valueAnimation, .valueString, .valueDirection, .valuePoint:
            instructions.append(Constant(value: current.value))
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
    return Script(states: statePointers, initialState: initialState ?? "default", instructions: instructions)
}

extension String {
    var script: Script {
        do {
            return try parse(code: self)
        } catch {
            print("Parse error: \(error)")
            return .empty
        }
    }
}
