//
//  Lexer.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

enum LexerError: Error {
    case expectedTokenNotFound(current: FoundToken, expected: [Token], found: String)
    case badIndent(current: FoundToken, expectedMultipleOf: Int, found: Int)
}

protocol Tokenizer {
    func tokenize(code: String) -> [FoundToken]
    func tokenize(code: String, onToken: (FoundToken) -> Void)
}

extension Tokenizer {
    func tokenize(code: String) -> [FoundToken] {
        var tokens: [FoundToken] = []
        tokenize(code: code) { token in
            tokens.append(token)
        }
        return tokens
    }
}
