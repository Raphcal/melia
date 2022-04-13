//
//  CodeEditor.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation
import SwiftUI

struct CodeEditor: NSViewRepresentable {
    typealias NSViewType = NSTextView

    func makeNSView(context: Context) -> NSTextView {
        return NSTextView()
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator {
        
    }
}
