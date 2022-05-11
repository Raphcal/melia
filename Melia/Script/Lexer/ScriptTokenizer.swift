//
//  ScriptTokenizer.swift
//  Melia
//
//  Created by Raphaël Calabro on 11/05/2022.
//

import Foundation

struct ScriptTokenizer: Tokenizer {
    func tokenize(code: String, onToken: (FoundToken) -> Void) {
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
                onToken(FoundToken(token: .syntaxError, matches: [String(code[startIndex ..< endIndex])], range: from ..< min(code.count, from + 10)))
                return
            }
            current = next

            let wholeMatch = next.matches[0]
            if let indent = indent, next.token == .indent && wholeMatch.count > indent.count {
                if wholeMatch.count % indent.count != 0 {
                    let start = from - wholeMatch.count
                    onToken(FoundToken(token: .syntaxError, matches: [wholeMatch], range: start ..< start + wholeMatch.count))
                    return
                }
                for start in stride(from: from - wholeMatch.count, to: from, by: indent.count) {
                    onToken(FoundToken(token: .indent, matches: [indent], range: start ..< start + indent.count))
                }
            } else {
                if indent == nil && next.token == .indent {
                    indent = wholeMatch
                }
                onToken(next)
            }
        }
        if current.token != .newLine {
            onToken(FoundToken(token: .newLine, matches: [], range: from ..< from))
        }
        onToken(FoundToken(token: .endOfFile, matches: [], range: from ..< from))
    }

}
