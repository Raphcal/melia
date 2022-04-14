//
//  Token.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

enum Token {
    case newLine, indent
    case declareStart, declareName, declareSeparator, declareType
    case stateStart, stateName, stateEnd
    case groupStart, groupEnd
    case instructionStart, instructionArgName
    case setStart, setVariableName, setEqual
    case valuePoint, valueInt, valueDuration, valueDirection, valueAnimation, valueVariable
    case addOrSubstract, multiplyOrDivide, unaryOperator, braceOpen, braceClose

    var expected: [Token] {
        switch self {
        case .newLine:
            return [.indent, .declareStart, .stateStart, .setStart, .groupStart, .instructionStart]
        case .indent:
            return [.setStart, .groupStart, .instructionStart]
        case .declareStart:
            return [.declareName]
        case .declareName:
            return [.declareSeparator]
        case .declareSeparator:
            return [.declareType]
        case .declareType:
            return [.newLine]
        case .stateStart:
            return [.stateName]
        case .stateName:
            return [.stateEnd]
        case .stateEnd:
            return [.newLine, .instructionStart, .setStart]
        case .groupStart:
            return [.valueDuration, .valueAnimation, .valueVariable]
        case .groupEnd:
            return [.newLine, .instructionStart, .setStart]
        case .instructionStart:
            return [.instructionArgName, .newLine]
        case .instructionArgName:
            return [.valueDuration, .valueInt, .valuePoint, .valueDirection, .valueAnimation, .valueVariable, .braceOpen]
        case .setStart:
            return [.setVariableName]
        case .setVariableName:
            return [.setEqual]
        case .setEqual:
            return [.valueDuration, .valueInt, .valuePoint, .valueDirection, .valueAnimation, .valueVariable, .braceOpen]
        case .valuePoint:
            return [.addOrSubstract, .multiplyOrDivide, .braceClose, .instructionArgName, .newLine]
        case .valueInt:
            return [.addOrSubstract, .multiplyOrDivide, .braceClose, .instructionArgName, .newLine]
        case .valueDuration:
            return [.instructionArgName, .newLine, .groupEnd]
        case .valueDirection:
            return [.instructionArgName, .newLine]
        case .valueAnimation:
            return [.instructionArgName, .newLine, .groupEnd]
        case .valueVariable:
            return [.addOrSubstract, .multiplyOrDivide, .braceClose, .instructionArgName, .groupEnd, .newLine]
        case .addOrSubstract:
            return [.valueInt, .valuePoint, .valueVariable, .braceOpen]
        case .multiplyOrDivide:
            return [.valueInt, .valuePoint, .valueVariable, .braceOpen]
        case .unaryOperator:
            return [.valueInt, .valuePoint, .valueVariable, .braceOpen]
        case .braceOpen:
            return [.valueInt, .valuePoint, .valueVariable]
        case .braceClose:
            return [.addOrSubstract, .multiplyOrDivide, .instructionArgName, .newLine]
        }
    }

    private var patternString: String {
        switch self {
        case .newLine:
            return "\n"
        case .indent:
            return " +"
        case .declareStart:
            return "var +"
        case .declareName:
            return "([a-zA-Z][a-zA-Z0-9_]*) *"
        case .declareSeparator:
            return ": *"
        case .declareType:
            return "(sprite|int|point) *"
        case .stateStart:
            return "state +"
        case .stateName:
            return "([a-zA-Z0-9]+) *"
        case .stateEnd:
            return ": *"
        case .groupStart:
            return "(during|if|else if|else) +"
        case .groupEnd:
            return ": *"
        case .instructionStart:
            return "([a-z]+) *"
        case .instructionArgName:
            return ", *([a-z]+) *: *"
        case .setStart:
            return "set +"
        case .setVariableName:
            return "([a-z][a-zA-Z0-9_.]*) *"
        case .setEqual:
            return "= *"
        case .valuePoint:
            return "\\(([0-9]+), *([0-9]+)\\) *"
        case .valueInt:
            return "([0-9][0-9_]*) *"
        case .valueDuration:
            return "([0-9][0-9_]*)(ms|s|min) *"
        case .valueDirection:
            return "(foward|backward|up|down|left|right) *"
        case .valueAnimation:
            return "(stand|walk|run|skid|jump|fall|shaky|bounce|duck|raise|appear|disappear|attack|hurt|die) *"
        case .valueVariable:
            return "([a-z][a-zA-Z0-9_.]*) *"
        case .addOrSubstract:
            return "([+-]) *"
        case .multiplyOrDivide:
            return "([*/]) *"
        case .unaryOperator:
            return "-"
        case .braceOpen:
            return "\\( *"
        case .braceClose:
            return "\\) *"
        }
    }

    var pattern: Pattern {
        return Pattern(pattern: self.patternString)
    }

    var priority: Int {
        switch self {
        case .multiplyOrDivide:
            return 2
        case .addOrSubstract:
            return 1
        default:
            return 0
        }
    }

    var isBlank: Bool {
        return self == .newLine || self == .indent
    }
}
