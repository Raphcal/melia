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
    @State private var code = ""
    @State private var mapIndex = 0
    @State private var definitionIndex = 0

    var body: some View {
        HStack {
            TextEditor(text: $code)
                .font(.custom("Fira Code", size: 14))
            GeometryReader { geometry in
                OpenGLView(rendererContext: RendererContext(
                    map: document.project.root.maps.memory![mapIndex],
                    spriteDefinitions: document.project.root.sprites,
                    definitionIndex: definitionIndex,
                    frameSize: MELSize(width: GLfloat(geometry.size.width), height: GLfloat(geometry.size.height)),
                    script: code.script))
            }
        }
        .toolbar {
            ToolbarItem {
                Picker("Map", selection: $mapIndex) {
                    ForEach(0 ..< document.project.root.maps.count, id: \.self) { index in
                        Label(document.project.root.maps[index].nameAsString, systemImage: "map")
                    }
                }
            }
            ToolbarItem {
                Picker("Sprite", selection: $definitionIndex) {
                    ForEach(0 ..< document.project.root.sprites.count, id: \.self) { index in
                        Label(document.project.root.sprites[index].nameAsString, systemImage: "hare")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: MeliaDocument())
    }
}
