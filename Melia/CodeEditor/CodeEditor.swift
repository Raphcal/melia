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
        textView.backgroundColor = .white
        textView.font = NSFont(name: "Fira Code", size: 14)
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

        init(script: Binding<Script>) {
            self._script = script
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
                // TODO: Changer les attributs à partir du 1er token modifié
                for token in script.tokens {
                    textStorage.setAttributes(token.token.textAttributes, range: NSRange(location: token.range.startIndex, length: min(token.range.endIndex, textView.string.count) - token.range.startIndex))
                }
                textView.setSpellingState(0, range: NSRange(location: 0, length: textView.string.count))
            } catch {
                print("Parse error:\(error)")
                if case let LexerError.expectedTokenNotFound(current: current, expected: _, found: _) = error {
                    textView.setSpellingState(NSAttributedString.SpellingState.spelling.rawValue, range: NSRange(location: current.range.endIndex, length: 1))
                }
            }
        }
    }
}
