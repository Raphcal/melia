//
//  CGrammar.swift
//  Melia
//
//  Created by Raphaël Calabro on 11/05/2022.
//

import Foundation
import AppKit

struct CGrammar: Grammar {
    static let statementStart = [Token.comment, .preprocessorDirective, .braceOpen, .keyword, .instructionStart, .valueVariable, .groupEnd]
    static let anyValue = [Token.valueDecimal, .valueInt, .valueString, .valueBoolean, .valueAnimation, .instructionStart, .valueVariable]
    static let anyBinaryOperator = [Token.addOrSubstract, .multiplyOrDivide, .andOrOr]

    func tokensExpected(after token: Token) -> [Token] {
        switch token {
        case .newLine:
            return [.newLine, .indent, .braceClose] + CGrammar.statementStart
        case .groupEnd:
            return [.newLine]
        case .preprocessorDirective:
            return [.newLine, .braceOpen, .valueVariable, .valueString, .comment]
        case .comment:
            return [.newLine]
        case .braceOpen:
            return [.newLine, .braceClose, .instructionArgument] + CGrammar.anyValue + CGrammar.statementStart
        case .braceClose:
            return [.newLine, .groupEnd, .braceClose, .instructionArgument] + Token.anyBinaryOperator + CGrammar.statementStart
        case .keyword:
            return [.keyword, .braceOpen, .instructionStart, .valueVariable]
        case .instructionStart:
            return [.braceOpen, .braceClose, .unaryOperator, .valueVariable, .instructionArgument, .groupEnd]
        case .instructionArgument:
            return [.newLine, .braceOpen, .braceClose, .groupEnd] + CGrammar.anyValue
        case .valueVariable:
            return [.newLine, .groupEnd, .braceOpen, .braceClose, .instructionArgument, .instructionStart, .valueVariable, .andOrOr, .setStart] + CGrammar.anyBinaryOperator
        case .valueInt, .valueDecimal, .valueBoolean, .valueString, .valueAnimation:
            return [.newLine, .groupEnd, .braceClose, .instructionArgument] + CGrammar.anyBinaryOperator
        case .unaryOperator:
            return [.keyword, .braceOpen] + CGrammar.anyValue
        case .addOrSubstract, .multiplyOrDivide, .andOrOr:
            return [.braceOpen] + CGrammar.anyValue
        case .setStart:
            return [.braceOpen] + CGrammar.anyValue
        default:
            return []
        }
    }

    func patternString(for token: Token) -> String {
        switch token {
        case .newLine:
            return "\n *"
        case .comment:
            return "(?://[^\n]*)|(?:/\\*(?:.|\n)*?\\*/)"
        case .preprocessorDirective:
            return "# *(ifndef|ifdef|if|elif|else|endif|include|define|undef|line|error|pragma) *"
        case .keyword:
            return "(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|inline|int|long|register|restrict|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|_Bool|_Complex|_Imaginary) +"
        case .groupEnd:
            return "[:;]"
        case .instructionStart:
            return "([a-zA-Z_][a-zA-Z0-9_.]*) *\\([^)]*\\) *"
        case .instructionArgument:
            return ", *"
        case .setStart:
            return "(\\*=|/=|%=|-=|<<=|>>=|&=|^=|\\|=|=) *"
        case .valueInt:
            return "([0-9][0-9_]*) *"
        case .valueDecimal:
            return "([0-9][0-9_]*\\.[0-9][0-9_]*)f? *"
        case .valueVariable:
            return "([a-zA-Z_*&][a-zA-Z0-9_.]*) *"
        case .valueBoolean:
            return "(true|false) *"
        case .valueString:
            return "\\\"((?:\\\\\\\"|[^\"])*)\\\" *"
        case .valueAnimation:
            return "NULL"
        case .addOrSubstract:
            return "([+-]) *"
        case .multiplyOrDivide:
            return "([*/]) *"
        case .unaryOperator:
            return "(++|--|[&*~!-]) *"
        case .andOrOr:
            return "(->|&&|\\|\\||==|!=) *"
        case .braceOpen:
            return "[({<\\[] *"
        case .braceClose:
            return "[)}>\\]] *"
        default:
            return ""
        }
    }

    func textAttributes(for token: Token, regularFont: NSFont, boldFont: NSFont) -> [NSAttributedString.Key : Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: regularFont,
            .foregroundColor: NSColor.black,
            .backgroundColor: NSColor.white
        ]
        switch token {
        case .state, .groupStart, .groupEnd:
            attributes[.font] = boldFont
            attributes[.foregroundColor] = NSColor.systemPurple
        case .instructionStart:
            attributes[.foregroundColor] = NSColor.systemPurple
        case .keyword:
            attributes[.font] = boldFont
            attributes[.foregroundColor] = NSColor.purple
        case .instructionArgument:
            attributes[.font] = boldFont
        case .valueInt, .valueDecimal, .valuePoint, .valueBoolean, .valueDuration:
            attributes[.foregroundColor] = NSColor.blue
        case .valueString, .valueAnimation, .valueDirection:
            attributes[.foregroundColor] = NSColor.systemRed
        case .comment:
            attributes[.foregroundColor] = NSColor.darkGray
        case .preprocessorDirective:
            attributes[.foregroundColor] = NSColor.brown
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
