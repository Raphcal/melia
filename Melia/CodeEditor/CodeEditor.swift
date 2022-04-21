//
//  CodeEditor.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation
import SwiftUI

struct CodeEditor: NSViewRepresentable {
    var scriptName: String
    @Binding var code: String?
    @Binding var script: Script
    @Environment(\.undoManager) private var undoManager: UndoManager?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.font = context.coordinator.regularFont
        textView.isAutomaticQuoteSubstitutionEnabled = false

        textView.string = code ?? ""
        textView.delegate = context.coordinator

        DispatchQueue.main.async {
            context.coordinator.textDidChange(Notification(name: NSTextView.willChangeNotifyingTextViewNotification, object: textView))
        }
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else {
            return
        }
        if scriptName != context.coordinator.scriptName {
            context.coordinator.scriptDidChange(scriptName: scriptName, code: $code, script: $script)
            textView.string = code ?? ""
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(scriptName: scriptName, code: $code, script: $script, undoManager: undoManager)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var code: String?
        @Binding var script: Script
        var scriptName: String
        var undoManager: UndoManager?

        let regularFont: NSFont
        let boldFont: NSFont

        var snapshot: CodeSnapshot?

        init(scriptName: String, code: Binding<String?>, script: Binding<Script>, undoManager: UndoManager?) {
            self.scriptName = scriptName
            self._code = code
            self._script = script
            self.undoManager = undoManager
            self.regularFont = NSFont(name: "Fira Code", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            self.boldFont = NSFont(name: "Fira Code Bold", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        }

        final func scriptDidChange(scriptName: String, code: Binding<String?>, script: Binding<Script>) {
            self.scriptName = scriptName
            self._code = code
            self._script = script
            self.snapshot = nil
            undoManager?.removeAllActions()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let textStorage = textView.textStorage
            else {
                print("Not a text view or no storage.")
                return
            }
            let textViewString = textView.string
            if (code == nil && textViewString.isEmpty) || code != textViewString {
                if let undoManager = undoManager,
                   snapshot == nil || (textViewString.last == "\n" && textViewString != snapshot!.code) {
                    let aSnapshot = CodeSnapshot(code: $code, undoManager: undoManager)
                    undoManager.registerUndo(withTarget: aSnapshot) { _ in aSnapshot.undo() }
                    snapshot = aSnapshot
                }
                // TODO: Ajouter l'indentation ?
                code = textViewString
            }
            do {
                script = try parse(code: textViewString)
                for token in script.tokens {
                    let attributes = token.token.textAttributes(regularFont: regularFont, boldFont: boldFont)
                    let range = NSRange(location: token.range.startIndex, length: min(token.range.endIndex, textViewString.count) - token.range.startIndex)
                    textStorage.setAttributes(attributes, range: range)
                }
                textView.setSpellingState(0, range: NSRange(location: 0, length: textViewString.count))
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

struct CodeEditor_Previews: PreviewProvider {
    @State private static var script = Script.empty
    @State private static var code: String? = """
state main:
    // Attend 1s
    set self.animation = stand
    during 1s: wait
    // Bouge
    set self.animation = walk
    set center = self.center
    during 1s, ease: true:
        set self.center = center + (128, 0) * progress * self.direction.value
    set self.direction = self.direction.reverse
"""

    static var previews: some View {
        CodeEditor(scriptName: "no name", code: $code, script: $script)
    }
}
