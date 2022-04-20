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

    var body: some View {
        NavigationView {
            List(document.project.scripts.keys.map({ String(utf8String: $0)! }), id: \.self) { script in
                NavigationLink(destination: ScriptView(code: $document.project.scripts[script], sprites: document.project.root.sprites, maps: document.project.root.maps)) {
                    Label(script, systemImage: "text.alignleft")
                }
            }
            Text("Select a script")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: MeliaDocument())
    }
}
