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
    case comment, preprocessorDirective
    case keyword
    case syntaxError

    // MARK: - Token classes
    static var anyValue: [Token] {
        return [.unaryOperator, .valueDuration, .valueDecimal, .valueInt, .valueBoolean, .valuePoint, .valueDirection, .valueAnimation, .valueVariable, .valueString, .braceOpen]
    }
    static var anyNumericValue: [Token] {
        return [.unaryOperator, .valueDuration, .valueDecimal, .valueInt, .valuePoint, .valueVariable, .braceOpen]
    }
    static var anyBinaryOperator: [Token] {
        return [.addOrSubstract, .multiplyOrDivide]
    }

    // MARK: - Syntax

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
