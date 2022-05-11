//
//  Previews.swift
//  Melia
//
//  Created by Raphaël Calabro on 04/05/2022.
//

import SwiftUI
import MeliceFramework

struct Previews: View {
    var scriptName = "none"
    @Binding var code: String?
    var sprites: MELSpriteDefinitionList
    var maps: MELMutableMapList

    @Binding var tokens: [FoundToken]
    @Binding var mapIndex: Int
    @Binding var definitionIndex: Int
    @Binding var origin: MELPoint

    @State private var selectedFile = GeneratedFile.code
    @State private var sideView = SideView.generatedCode

    var body: some View {
        if sideView == .gamePreview {
            OpenGLView(rendererContext: RendererContext(
                map: maps[mapIndex],
                spriteDefinitions: sprites,
                definitionIndex: definitionIndex,
                origin: origin,
                tokens: tokens))
            .toolbar {
                ToolbarItemGroup {
                    Picker("Map", selection: $mapIndex) {
                        ForEach(0 ..< maps.count, id: \.self) { index in
                            Text("􀙊 \(maps[index].nameAsString)")
                        }
                    }
                    Picker("Sprite", selection: $definitionIndex) {
                        ForEach(0 ..< sprites.count, id: \.self) { index in
                            Text("􀓎 \(sprites[index].nameAsString)")
                        }
                    }
                }
                ToolbarItem {
                    Picker("View", selection: $sideView) {
                        Text("􀛸 Game Preview")
                            .tag(SideView.gamePreview)
                        Text("􀅮 Generated Code")
                            .tag(SideView.generatedCode)
                    }
                    .pickerStyle(.segmented)
                }
            }
        } else {
            GeneratedCodeView(tokens: $tokens, selectedFile: $selectedFile, sprites: sprites, definitionIndex: $definitionIndex)
                .toolbar {
                    ToolbarItem {
                        Picker("File", selection: $selectedFile) {
                            Text("􀂢 header")
                                .tag(GeneratedFile.header)
                            Text("􀂘 code")
                                .tag(GeneratedFile.code)
                        }
                        .pickerStyle(.segmented)
                    }
                    ToolbarItem {
                        Picker("View", selection: $sideView) {
                            Text("􀛸 Game Preview")
                                .tag(SideView.gamePreview)
                            Text("􀅮 Generated Code")
                                .tag(SideView.generatedCode)
                        }
                        .pickerStyle(.segmented)
                    }
                }
        }
    }
}
