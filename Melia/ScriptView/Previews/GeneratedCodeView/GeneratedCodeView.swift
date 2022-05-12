//
//  GeneratedCodeView.swift
//  Melia
//
//  Created by Raphaël Calabro on 04/05/2022.
//

import SwiftUI
import MeliceFramework

struct GeneratedCodeView: View {
    @Binding var tokens: [FoundToken]
    @Binding var selectedFile: GeneratedFile

    let sprites: MELSpriteDefinitionList
    @Binding var definitionIndex: Int

    @State private var generatedCode: String?
    @State private var generatedCodeTokens = [FoundToken]()

    var body: some View {
        CodeEditor(code: $generatedCode, tokens: $generatedCodeTokens)
            .editable(false)
            .grammar(CGrammar())
        .onChange(of: tokens) { tokens in
            regenerateCode()
        }
        .onChange(of: selectedFile) { newValue in
            regenerateCode()
        }
    }

    func regenerateCode() {
        DispatchQueue.parse.async {
            let generator = PlaydateCodeGenerator(tree: TokenTree(tokens: tokens), for: sprites[definitionIndex])
            let code = selectedFile == .header ? generator.headerFile : generator.codeFile
            DispatchQueue.main.sync {
                generatedCode = code
            }
        }
    }
}
