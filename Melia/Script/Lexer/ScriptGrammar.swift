//
//  ScriptGrammar.swift
//  Melia
//
//  Created by Raphaël Calabro on 11/05/2022.
//

import Foundation
import AppKit

struct ScriptGrammar: Grammar {
    func tokensExpected(after token: Token) -> [Token] {
        switch token {
        case .newLine:
            return [.newLine, .indent, .comment, .state, .setStart, .groupStart, .instructionStart, .braceOpen] + Token.anyValue
        case .indent:
            return [.comment, .setStart, .groupStart, .instructionStart]
        case .state:
            return [.newLine, .instructionStart, .setStart]
        case .groupStart:
            return [.valueDuration, .valueBoolean, .valueVariable]
        case .groupEnd:
            return [.newLine, .instructionStart, .setStart]
        case .instructionStart:
            return [.instructionArgument, .newLine]
        case .instructionArgument:
            return Token.anyValue
        case .setStart:
            return [.instructionStart] + Token.anyValue
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
            return Token.anyNumericValue
        case .andOrOr:
            return [.valueBoolean, .valueVariable]
        case .braceOpen:
            return Token.anyNumericValue
        case .braceClose:
            return Token.anyBinaryOperator + [.braceClose, .instructionArgument, .newLine]
        case .comment:
            return [.newLine]
        default:
            return []
        }
    }

    func patternString(for token: Token) -> String {
        switch token {
        case .newLine:
            return "\n"
        case .indent:
            return "(?: |\t)+"
        case .state:
            return "state +([a-zA-Z0-9]+) *: *"
        case .groupStart:
            return "(during|while|jump|if|else if|else) +"
        case .groupEnd:
            return ": *"
        case .instructionStart:
            return "(move|shoot|new|wait) *"
        case .instructionArgument:
            return ", *([a-z]+) *: *"
        case .setStart:
            return "([a-z][a-zA-Z0-9_.]*) *= *"
        case .valuePoint:
            return "\\((-?[0-9.]+), *(-?[0-9.]+)\\) *"
        case .valueInt:
            return "([0-9][0-9_]*) *"
        case .valueDecimal:
            return "([0-9][0-9_]*\\.[0-9][0-9_]*) *"
        case .valueDuration:
            return "([0-9][0-9._]*)(ms|s|min) *"
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
            return "(-|!|abs|cos|sin|sqrt) *"
        case .andOrOr:
            return "(and|&&|or|\\|\\|) *"
        case .braceOpen:
            return "\\( *"
        case .braceClose:
            return "\\) *"
        case .comment:
            return "//[^\n]*"
        default:
            return ""
        }
    }

    func textAttributes(for token: Token, regularFont: NSFont, boldFont: NSFont) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: regularFont,
            .foregroundColor: NSColor.black,
            .backgroundColor: NSColor.white
        ]
        switch token {
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
        case .syntaxError:
            attributes[.spellingState] = NSAttributedString.SpellingState.grammar.rawValue
            attributes[.backgroundColor] = NSColor.red
            attributes[.foregroundColor] = NSColor.white
        default:
            break
        }
        return attributes
    }
}
