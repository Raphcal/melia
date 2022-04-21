//
//  ContentView.swift
//  Melia
//
//  Created by Raphaël Calabro on 02/04/2022.
//

import SwiftUI
import MeliceFramework

struct ContentView: View {
    @ObservedObject var document: MeliaDocument
    @State private var scriptName: String?

    var body: some View {
        NavigationView {
            let scriptNames: [String] = document.project.scripts.keys.map({ String(utf8String: $0)! })
            List(scriptNames, id: \.self, selection: $scriptName) { script in
                Label(script, systemImage: "text.alignleft")
            }
            .frame(width: 200)
            .toolbar {
                ToolbarItem {
                    Button {
                        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                    } label: {
                        Label("Hide or show the scripts", systemImage: "sidebar.squares.leading")
                    }
                }
            }
            if let scriptName = scriptName {
                ScriptView(scriptName: scriptName, code: $document.project.scripts[scriptName], sprites: document.project.root.sprites, maps: document.project.root.maps)
            } else {
                Text("Select a script")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: MeliaDocument())
    }
}
