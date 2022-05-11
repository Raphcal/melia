//
//  CodeEditor.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation
import SwiftUI
import Combine

struct CodeEditor: NSViewRepresentable {
    var scriptName: String?
    var isEditable = true
    @Binding var code: String?
    @Binding var tokens: [FoundToken]
    @Environment(\.undoManager) private var undoManager: UndoManager?

    func editable(_ isEditable: Bool) -> CodeEditor {
        var copy = self
        copy.isEditable = isEditable
        return copy
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.font = context.coordinator.regularFont
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isEditable = isEditable

        textView.string = code ?? ""
        textView.delegate = context.coordinator

        DispatchQueue.parse.async {
            context.coordinator.colorizeSyntax(textView: textView)
        }
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else {
            print("No text view")
            return
        }
        textView.isEditable = isEditable
        if code != textView.string {
            textView.string = code ?? ""
        }
        if scriptName != context.coordinator.scriptName {
            context.coordinator.scriptDidChange(textView: textView, scriptName: scriptName, code: $code, tokens: $tokens)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(scriptName: scriptName, code: $code, tokens: $tokens, undoManager: undoManager)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var code: String?
        @Binding var tokens: [FoundToken]
        var scriptName: String?
        var undoManager: UndoManager?

        let regularFont: NSFont
        let boldFont: NSFont

        var snapshot: CodeSnapshot?

        init(scriptName: String?, code: Binding<String?>, tokens: Binding<[FoundToken]>, undoManager: UndoManager?) {
            self.scriptName = scriptName
            self._code = code
            self._tokens = tokens
            self.undoManager = undoManager
            self.regularFont = NSFont(name: "Fira Code", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            self.boldFont = NSFont(name: "Fira Code Bold", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
            super.init()
        }

        func scriptDidChange(textView: NSTextView, scriptName: String?, code: Binding<String?>, tokens: Binding<[FoundToken]>) {
            self.scriptName = scriptName
            self._code = code
            self._tokens = tokens
            self.snapshot = nil
            undoManager?.removeAllActions()

            textView.string = self.code ?? ""
            DispatchQueue.main.async {
                self.colorizeSyntax(textView: textView)
            }
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                codeDidChange(textView: textView)
            }
        }

        func codeDidChange(textView: NSTextView) {
            print("codeDidChange")
            let newCode = textView.string
            if (code == nil && newCode.isEmpty) || newCode != code {
                if let undoManager = undoManager,
                   snapshot == nil || (newCode.last == "\n" && newCode != snapshot!.code) {
                    let aSnapshot = CodeSnapshot(code: $code, undoManager: undoManager)
                    undoManager.registerUndo(withTarget: aSnapshot) { _ in aSnapshot.undo() }
                    snapshot = aSnapshot
                }
                // TODO: Ajouter l'indentation ?
                code = newCode
            }
            DispatchQueue.parse.async { [self] in
                colorizeSyntax(textView: textView)
            }
        }

        func colorizeSyntax(textView: NSTextView) {
            let regularFont = self.regularFont
            let boldFont = self.boldFont
            let code = self.code ?? ""
            var tokens = [FoundToken]()
            var anError: Error?
            do {
                tokens = try lex(code: code)
            } catch {
                anError = error
            }

            DispatchQueue.main.async {
                guard let textStorage = textView.textStorage else {
                    print("No storage.")
                    return
                }

                if let error = anError {
                    var attributes = Token.newLine.textAttributes(regularFont: regularFont, boldFont: boldFont)
                    var range: NSRange?

                    if case let LexerError.expectedTokenNotFound(current: current, expected: expected, found: _) = error {
                        let expectedTokens = expected.map({ "\($0)" }).joined(separator: ", ")
                        attributes[.toolTip] = "Expected one of \(expectedTokens) after \(current.token)."
                        if current.range.endIndex < textView.string.count {
                            range = NSRange(location: current.range.endIndex, length: 1)
                        }
                    } else if case let LexerError.badIndent(current: current, expectedMultipleOf: base, found: found) = error {
                        attributes[.toolTip] = "Expected indentation size to be a multiple of \(base) but was \(found)."
                        if current.range.startIndex < textView.string.count {
                            range = NSRange(location: current.range.startIndex, length: min(current.range.endIndex, textView.string.count) - current.range.startIndex)
                        }
                    } else {
                        print("Parse error:\(error)")
                    }
                    if let range = range {
                        textStorage.setAttributes(attributes, range: range)
                        textView.setSpellingState(NSAttributedString.SpellingState.spelling.rawValue, range: range)
                    }
                } else {
                    self.tokens = tokens
                    for token in tokens {
                        let attributes = token.token.textAttributes(regularFont: regularFont, boldFont: boldFont)
                        let range = NSRange(location: token.range.startIndex, length: min(token.range.endIndex, textView.string.count) - token.range.startIndex)
                        textStorage.setAttributes(attributes, range: range)
                    }
                    textView.setSpellingState(0, range: NSRange(location: 0, length: textView.string.count))
                }
            }
        }
    }
}

struct CodeEditor_Previews: PreviewProvider {
    @State private static var tokens = [FoundToken]()
    @State private static var code: String? = """
state main:
    // Attend 1s
    self.animation = stand
    during 1s: wait
    // Bouge
    self.animation = walk
    center = self.center
    during 1s, ease: true:
        self.center = center + (128, 0) * progress * self.direction.value
    self.direction = self.direction.reverse
"""

    static var previews: some View {
        CodeEditor(scriptName: "no name", code: $code, tokens: $tokens)
    }
}
