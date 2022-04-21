//
//  CodeSnapshot.swift
//  Melia
//
//  Created by Raphaël Calabro on 21/04/2022.
//

import SwiftUI

class CodeSnapshot {
    @Binding var code: String?
    weak var undoManager: UndoManager?

    var before: String?
    var after: String?

    init(code: Binding<String?>, undoManager: UndoManager?) {
        self._code = code
        self.undoManager = undoManager
        self.before = code.wrappedValue
    }

    func undo() {
        guard let undoManager = undoManager else {
            return
        }
        if after == nil {
            after = code
        }
        code = before
        undoManager.registerUndo(withTarget: self) { _ in self.redo() }
    }

    fileprivate func redo() {
        guard let undoManager = undoManager else {
            return
        }
        code = after
        undoManager.registerUndo(withTarget: self) { _ in self.undo() }
    }
}
