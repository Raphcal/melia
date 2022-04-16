//
//  Token.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

enum Token {
    // MARK: - Tokens
    case newLine, indent
    case stateStart, stateName, stateEnd
    case groupStart, groupEnd
    case instructionStart, instructionArgument
    case setStart, setVariableName, setEqual
    case valueInt, valueDecimal, valueDuration, valueBoolean, valuePoint, valueDirection, valueAnimation, valueVariable, valueString
    case braceOpen, braceClose
    case addOrSubstract, multiplyOrDivide, unaryOperator
    case andOrOr

    // MARK: - Token classes
    var anyValue: [Token] {
        return [.valueDuration, .valueInt, .valueDecimal, .valueBoolean, .valuePoint, .valueDirection, .valueAnimation, .valueVariable, .valueString, .braceOpen]
    }
    var anyNumericValue: [Token] {
        return [.valueDuration, .valueInt, .valueDecimal, .valuePoint, .valueVariable]
    }
    var anyBinaryOperator: [Token] {
        return [.addOrSubstract, .multiplyOrDivide]
    }

    // MARK: - Syntax
    var expected: [Token] {
        switch self {
        case .newLine:
            return [.indent, .stateStart, .setStart, .groupStart, .instructionStart, .braceOpen] + anyValue
        case .indent:
            return [.setStart, .groupStart, .instructionStart]
        case .stateStart:
            return [.stateName]
        case .stateName:
            return [.stateEnd]
        case .stateEnd:
            return [.newLine, .instructionStart, .setStart]
        case .groupStart:
            return [.valueDuration,.valueBoolean, .valueVariable]
        case .groupEnd:
            return [.newLine, .instructionStart, .setStart]
        case .instructionStart:
            return [.instructionArgument, .newLine]
        case .instructionArgument:
            return anyValue
        case .setStart:
            return [.setVariableName]
        case .setVariableName:
            return [.setEqual]
        case .setEqual:
            return [.instructionStart] + anyValue
        case .valuePoint, .valueInt, .valueDecimal:
            return anyBinaryOperator + [.braceClose, .instructionArgument, .newLine]
        case .valueBoolean:
            return [.andOrOr, .instructionArgument, .newLine, .groupEnd]
        case .valueDuration:
            return [.instructionArgument, .newLine, .groupEnd]
        case .valueDirection:
            return [.instructionArgument, .newLine]
        case .valueString:
            return [.instructionArgument, .newLine]
        case .valueAnimation:
            return [.instructionArgument, .newLine, .groupEnd]
        case .valueVariable:
            return anyBinaryOperator + [.braceClose, .instructionArgument, .groupEnd, .newLine]
        case .addOrSubstract, .multiplyOrDivide, .unaryOperator :
            return anyNumericValue + [.braceOpen]
        case .andOrOr:
            return [.valueBoolean, .valueVariable]
        case .braceOpen:
            return anyNumericValue
        case .braceClose:
            return anyBinaryOperator + [.instructionArgument, .newLine]
        }
    }

    private var patternString: String {
        switch self {
        case .newLine:
            return "\n"
        case .indent:
            return "(?: |\t)+"
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
            return "(move|jump|shoot|new|wait) *"
        case .instructionArgument:
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
        case .valueDecimal:
            return "([0-9][0-9_]*\\.[0-9][0-9_]*) *"
        case .valueDuration:
            return "([0-9][0-9_]*)(ms|s|min) *"
        case .valueDirection:
            return "(up|down|left|right) *"
        case .valueAnimation:
            return "(stand|walk|run|skid|jump|fall|shaky|bounce|duck|raise|appear|disappear|attack|hurt|die) *"
        case .valueVariable:
            return "([a-z][a-zA-Z0-9_.]*) *"
        case .valueBoolean:
            return "(true|false) *"
        case .valueString:
            return "\"([^\"]|\\\")\""
        case .addOrSubstract:
            return "([+-]) *"
        case .multiplyOrDivide:
            return "([*/]) *"
        case .unaryOperator:
            return "-|!"
        case .andOrOr:
            return "(and|&&|or|\\|\\|) *"
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
