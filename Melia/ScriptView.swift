//
//  ScriptView.swift
//  Melia
//
//  Created by Raphaël Calabro on 20/04/2022.
//

import SwiftUI
import MeliceFramework

struct ScriptView: View {
    var scriptName = "none"
    @Binding var code: String?
    var sprites: MELSpriteDefinitionList
    var maps: MELMutableMapList

    @Environment(\.undoManager) private var undoManager: UndoManager?

    @State private var script: Script = .empty

    @State private var mapIndex = 0
    @State private var definitionIndex = 0

    var body: some View {
        HStack(spacing: 0) {
            CodeEditor(scriptName: scriptName, code: $code, script: $script)
            GeometryReader { geometry in
                OpenGLView(rendererContext: RendererContext(
                    map: maps[mapIndex],
                    spriteDefinitions: sprites,
                    definitionIndex: definitionIndex,
                    frameSize: MELSize(width: GLfloat(geometry.size.width), height: GLfloat(geometry.size.height)),
                    script: script))
            }
            .onAppear(perform: {
                updateMapIndexAndDefinitionIndex(for: scriptName)
            })
            .onChange(of: scriptName) { newValue in
                updateMapIndexAndDefinitionIndex(for: newValue)
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

    func updateMapIndexAndDefinitionIndex(for scriptName: String) {
        for (mapIndex, map) in maps.enumerated() {
            for layer in map.layers {
                for sprite in layer.sprites {
                    let definitionIndex = Int(sprite.definitionIndex)
                    if let motionName = sprites[definitionIndex].motionName,
                       let spriteScriptName = String(utf8String: motionName),
                       scriptName == spriteScriptName {
                        self.mapIndex = mapIndex
                        self.definitionIndex = definitionIndex
                        return
                    }
                }
            }
        }
    }
}
