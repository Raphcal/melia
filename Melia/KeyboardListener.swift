//
//  KeyboardListener.swift
//  Melia
//
//  Created by Raphaël Calabro on 19/04/2022.
//

import Foundation
import SwiftUI

struct KeyboardListener<Content: View>: NSViewRepresentable {
    var content: () -> Content
    var onKeyUp: ((NSEvent) -> Void)?

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    func onKeyUp(_ listener: ((NSEvent) -> Void)?) -> KeyboardListener {
        var copy = self
        copy.onKeyUp = listener
        return copy
    }

    func makeNSView(context: Context) -> KeyboardListenerView {
        let view = KeyboardListenerView()
        view.onKeyUp = onKeyUp
        view.addSubview(NSHostingView(rootView: content()))
        return view
    }
    
    func updateNSView(_ nsView: KeyboardListenerView, context: Context) {
        nsView.onKeyUp = onKeyUp
        for subview in nsView.subviews {
            subview.removeFromSuperview()
        }
        nsView.addSubview(NSHostingView(rootView: content()))
    }

    class KeyboardListenerView: NSView {
        var onKeyUp: ((NSEvent) -> Void)?
        override func keyUp(with event: NSEvent) {
            onKeyUp?(event)
        }
        override var isOpaque: Bool {
            return false
        }
        override var acceptsFirstResponder: Bool {
            return true
        }
    }
}

struct KeyboardListener_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardListener {
            Text("Hello World!")
        }
    }
}
