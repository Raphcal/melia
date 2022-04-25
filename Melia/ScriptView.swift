//
//  ScriptView.swift
//  Melia
//
//  Created by Raphaël Calabro on 20/04/2022.
//

import SwiftUI
import MeliceFramework

fileprivate enum SideView {
    case gamePreview, generatedCode
}

struct ScriptView: View {
    var scriptName = "none"
    @Binding var code: String?
    var sprites: MELSpriteDefinitionList
    var maps: MELMutableMapList

    @Environment(\.undoManager) private var undoManager: UndoManager?

    @State private var script: Script = .empty

    @State private var mapIndex = 0
    @State private var definitionIndex = 0
    @State private var origin = MELPoint(x: 32, y: 32)

    @State private var sideView = SideView.generatedCode

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CodeEditor(scriptName: scriptName, code: $code, script: $script)
            Divider()
            if sideView == .gamePreview {
                OpenGLView(rendererContext: RendererContext(
                    map: maps[mapIndex],
                    spriteDefinitions: sprites,
                    definitionIndex: definitionIndex,
                    origin: origin,
                    script: script))
            } else {
                ScrollView {
                    Text("// TODO: Compiler en C")
                    .font(.custom("Fira Code", size: 12))
                    .padding(4)
                }
            }
        }
        .onAppear(perform: {
            updateMapIndexAndDefinitionIndex(for: scriptName)
        })
        .onChange(of: scriptName) { newValue in
            updateMapIndexAndDefinitionIndex(for: newValue)
        }
        .toolbar {
            ToolbarItemGroup {
                if sideView == .gamePreview {
                    Picker("Map", selection: $mapIndex) {
                        ForEach(0 ..< maps.count, id: \.self) { index in
                            Label(maps[index].nameAsString, systemImage: "map")
                        }
                    }
                    Picker("Sprite", selection: $definitionIndex) {
                        ForEach(0 ..< sprites.count, id: \.self) { index in
                            Label(sprites[index].nameAsString, systemImage: "hare")
                        }
                    }
                }
            }
            ToolbarItem {
                Picker("View", selection: $sideView) {
                    Label("Game Preview", systemImage: "gamecontroller")
                        .tag(SideView.gamePreview)
                    Label("Generated Code", systemImage: "function")
                        .tag(SideView.generatedCode)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }

    func updateMapIndexAndDefinitionIndex(for scriptName: String) {
        for (mapIndex, map) in maps.enumerated() {
            for layer in map.layers {
                for sprite in layer.sprites {
                    let definitionIndex = Int(sprite.definitionIndex)
                    let definition = sprites[definitionIndex]
                    if let motionName = definition.motionName,
                       let spriteScriptName = String(utf8String: motionName),
                       scriptName == spriteScriptName {
                        self.mapIndex = mapIndex
                        self.definitionIndex = definitionIndex
                        if let firstNonEmptyImage = MELSpriteDefinitionFirstNonEmptyImage(definition) {
                            origin = sprite.topLeft + MELPoint(firstNonEmptyImage.pointee.size) / 2
                        } else {
                            origin = sprite.topLeft
                        }
                        return
                    }
                }
            }
        }
    }
}

struct ScriptView_Previews: PreviewProvider {
    @State private static var code: String? = """
state main:
   self.animation = stand
   during 1s: wait
   self.animation = walk
   center = self.center
   during 1s, ease: true:
      self.center = center + (128, 0) * progress * self.direction.value
   self.direction = self.direction.reverse
"""

    static var previews: some View {
        ScriptView(code: $code, sprites: .empty, maps: .empty)
    }
}
