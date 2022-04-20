//
//  ScriptView.swift
//  Melia
//
//  Created by Raphaël Calabro on 20/04/2022.
//

import SwiftUI
import MeliceFramework

struct ScriptView: View {
    @Binding var code: String?
    var sprites: MELSpriteDefinitionList
    var maps: MELMutableMapList

    @State private var script: Script = .empty

    @State private var mapIndex = 0
    @State private var definitionIndex = 0

    var body: some View {
        HStack {
            CodeEditor(code: $code, script: $script)
            GeometryReader { geometry in
                OpenGLView(rendererContext: RendererContext(
                    map: maps[mapIndex],
                    spriteDefinitions: sprites,
                    definitionIndex: definitionIndex,
                    frameSize: MELSize(width: GLfloat(geometry.size.width), height: GLfloat(geometry.size.height)),
                    script: script))
            }
        }
        .toolbar {
            ToolbarItem {
                Picker("Map", selection: $mapIndex) {
                    ForEach(0 ..< maps.count, id: \.self) { index in
                        Label(maps[index].nameAsString, systemImage: "map")
                    }
                }
            }
            ToolbarItem {
                Picker("Sprite", selection: $definitionIndex) {
                    ForEach(0 ..< sprites.count, id: \.self) { index in
                        Label(sprites[index].nameAsString, systemImage: "hare")
                    }
                }
            }
        }
    }
}
