//
//  Grammar.swift
//  Melia
//
//  Created by Raphaël Calabro on 11/05/2022.
//

import Foundation
import AppKit

protocol Grammar {
    func tokensExpected(after token: Token) -> [Token]
    func pattern(for token: Token) -> Pattern
    func patternString(for token: Token) -> String
    func textAttributes(for token: Token, regularFont: NSFont, boldFont: NSFont) -> [NSAttributedString.Key: Any]
}

extension Grammar {
    func pattern(for token: Token) -> Pattern {
        return Pattern(pattern: patternString(for: token))
    }
}
