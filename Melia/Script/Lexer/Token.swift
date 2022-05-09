//
//  Token.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation
import AppKit

enum Token {
    // MARK: - Tokens
    case newLine, indent, endOfFile
    case state
    case groupStart, groupEnd
    case instructionStart, instructionArgument
    case setStart
    case valueInt, valueDecimal, valueDuration, valueBoolean, valuePoint, valueDirection, valueAnimation, valueVariable, valueString
    case braceOpen, braceClose
    case addOrSubstract, multiplyOrDivide, unaryOperator
    case andOrOr
    case comment

    // MARK: - Token classes
    static var anyValue: [Token] {
        return [.valueDuration, .valueDecimal, .valueInt, .valueBoolean, .valuePoint, .valueDirection, .valueAnimation, .valueVariable, .valueString, .braceOpen]
    }
    static var anyNumericValue: [Token] {
        return [.valueDuration, .valueDecimal, .valueInt, .valuePoint, .valueVariable]
    }
    static var anyBinaryOperator: [Token] {
        return [.addOrSubstract, .multiplyOrDivide]
    }

    // MARK: - Syntax
    var expected: [Token] {
        switch self {
        case .newLine:
            return [.newLine, .indent, .comment, .state, .setStart, .groupStart, .instructionStart, .braceOpen] + Token.anyValue
        case .indent:
            return [.comment, .setStart, .groupStart, .instructionStart]
        case .endOfFile:
            return []
        case .state:
            return [.newLine, .instructionStart, .setStart]
        case .groupStart:
            return [.valueDuration,.valueBoolean, .valueVariable]
        case .groupEnd:
            return [.newLine, .instructionStart, .setStart]
        case .instructionStart:
            return [.instructionArgument, .newLine]
        case .instructionArgument:
            return Token.anyValue
        case .setStart:
            return Token.anyValue
        case .valuePoint, .valueInt, .valueDecimal:
            return Token.anyBinaryOperator + [.braceClose, .instructionArgument, .newLine]
        case .valueBoolean:
            return [.andOrOr, .instructionArgument, .newLine, .groupEnd]
        case .valueDuration:
            return [.instructionArgument, .newLine, .groupEnd]
        case .valueDirection:
            return [.instructionArgument, .newLine]
        case .valueString:
            return [.instructionArgument, .newLine, .groupEnd]
        case .valueAnimation:
            return [.instructionArgument, .newLine, .groupEnd]
        case .valueVariable:
            return Token.anyBinaryOperator + [.braceClose, .instructionArgument, .groupEnd, .newLine]
        case .addOrSubstract, .multiplyOrDivide, .unaryOperator :
            return Token.anyNumericValue + [.braceOpen]
        case .andOrOr:
            return [.valueBoolean, .valueVariable]
        case .braceOpen:
            return Token.anyNumericValue
        case .braceClose:
            return Token.anyBinaryOperator + [.instructionArgument, .newLine]
        case .comment:
            return [.newLine]
        }
    }

    private var patternString: String {
        switch self {
        case .newLine:
            return "\n"
        case .indent:
            return "(?: |\t)+"
        case .endOfFile:
            return ""
        case .state:
            return "state +([a-zA-Z0-9]+) *: *"
        case .groupStart:
            return "(during|if|else if|else) +"
        case .groupEnd:
            return ": *"
        case .instructionStart:
            return "(move|jump|shoot|new|wait) *"
        case .instructionArgument:
            return ", *([a-z]+) *: *"
        case .setStart:
            return "([a-z][a-zA-Z0-9_.]*) *= *"
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
            return "\\\"((?:\\\\\\\"|[^\"])*)\\\" *"
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
        case .comment:
            return "//[^\n]*"
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

    func textAttributes(regularFont: NSFont, boldFont: NSFont) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: regularFont,
            .foregroundColor: NSColor.black,
            .backgroundColor: NSColor.white
        ]
        switch self {
        case .state, .instructionStart, .groupStart, .groupEnd:
            attributes[.font] = boldFont
            attributes[.foregroundColor] = NSColor.systemPurple
        case .instructionArgument:
            attributes[.font] = boldFont
        case .valueInt, .valueDecimal, .valuePoint, .valueBoolean, .valueDuration:
            attributes[.foregroundColor] = NSColor.blue
        case .valueString, .valueAnimation, .valueDirection:
            attributes[.foregroundColor] = NSColor.systemRed
        case .valueVariable:
            attributes[.foregroundColor] = NSColor.systemIndigo
        case .comment:
            attributes[.foregroundColor] = NSColor.darkGray
        default:
            break
        }
        return attributes
    }
}
