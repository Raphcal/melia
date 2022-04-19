//
//  CodeEditor.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation
import SwiftUI

struct CodeEditor: NSViewRepresentable {
    @Binding var script: Script

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = context.coordinator.regularFont
        textView.backgroundColor = .white
        textView.isAutomaticQuoteSubstitutionEnabled = false
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        // Vide.
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(script: $script)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var script: Script

        let regularFont: NSFont
        let boldFont: NSFont

        init(script: Binding<Script>) {
            self._script = script
            self.regularFont = NSFont(name: "Fira Code", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            self.boldFont = NSFont(name: "Fira Code Bold", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView
            else {
                print("Not a text view")
                return
            }
            guard let textStorage = textView.textStorage
            else {
                print("No textStorage")
                return
            }
            do {
                script = try parse(code: textView.string)
                for token in script.tokens {
                    let attributes = token.token.textAttributes(regularFont: regularFont, boldFont: boldFont)
                    let range = NSRange(location: token.range.startIndex, length: min(token.range.endIndex, textView.string.count) - token.range.startIndex)
                    textStorage.setAttributes(attributes, range: range)
                }
                textView.setSpellingState(0, range: NSRange(location: 0, length: textView.string.count))
            } catch {
                var attributes = Token.newLine.textAttributes(regularFont: regularFont, boldFont: boldFont)
                var range: NSRange?

                if case let LexerError.expectedTokenNotFound(current: current, expected: expected, found: _) = error {
                    let expectedTokens = expected.map({ "\($0)" }).joined(separator: ", ")
                    attributes[.toolTip] = "Expected one of \(expectedTokens) after \(current.token)."
                    range = NSRange(location: current.range.endIndex, length: 1)
                } else if case let LexerError.badIndent(current: current, expectedMultipleOf: base, found: found) = error {
                    attributes[.toolTip] = "Expected indentation size to be a multiple of \(base) but was \(found)."
                    range = NSRange(location: current.range.startIndex, length: current.range.count)
                } else {
                    print("Parse error:\(error)")
                }
                if let range = range {
                    textStorage.setAttributes(attributes, range: range)
                    textView.setSpellingState(NSAttributedString.SpellingState.spelling.rawValue, range: range)
                }
            }
        }
    }
}
