//
//  Lexer.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

enum LexerError: Error {
    case expectedTokenNotFound(current: FoundToken, expected: [Token], found: String)
    case badIndent(expectedMultipleOf: Int, found: Int)
}

func lex(code: String) throws -> [FoundToken] {
    var tokens: [FoundToken] = []
    try lex(code: code) { token in
        tokens.append(token)
    }
    return tokens
}

func lex(code: String, onToken: (FoundToken) throws -> Void) throws {
    var current = FoundToken(token: .newLine, matches: [], range: Range(0...0))
    var indent: String?
    var from = 0
    while from < code.count {
        var next: FoundToken?
        for expectedToken in current.token.expected {
            if let matches = expectedToken.pattern.matches(in: code, from: from) {
                next = FoundToken(token: expectedToken, matches: matches, range: from ..< from + matches[0].count)
                from += matches[0].count
                break
            }
        }
        guard let next = next else {
            let startIndex = code.index(code.startIndex, offsetBy: from)
            let endIndex = code.index(startIndex, offsetBy: min(code.count - from, 10))
            throw LexerError.expectedTokenNotFound(current: current, expected: current.token.expected, found: String(code[startIndex ..< endIndex]))
        }
        current = next

        let wholeMatch = next.matches[0]
        if let indent = indent, next.token == .indent && wholeMatch.count > indent.count {
            if wholeMatch.count % indent.count != 0 {
                throw LexerError.badIndent(expectedMultipleOf: indent.count, found: wholeMatch.count)
            }
            for start in stride(from: from - wholeMatch.count, to: from, by: indent.count) {
                try onToken(FoundToken(token: .indent, matches: [indent], range: start ..< start + indent.count))
            }
        } else {
            if indent == nil && next.token == .indent {
                indent = wholeMatch
            }
            try onToken(next)
        }
    }
    if current.token != .newLine {
        try onToken(FoundToken(token: .newLine, matches: [], range: Range(from...from)))
    }
}
