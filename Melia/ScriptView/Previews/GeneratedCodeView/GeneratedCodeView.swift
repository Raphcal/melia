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
        .onAppear {
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

struct GeneratedCodeView_Previews: PreviewProvider {
    @State private static var code: String = """
state main:
    // Attend 1s
    self.animation = stand
    during 1s: wait
    // Bouge
    self.animation = walk
    center = self.center
    during 1s, ease: true:
        self.center = center + (128, 0) * progress * self.direction.value
    self.direction = self.direction.reverse
"""
    @State private static var tokens: [FoundToken] = Tokenizer().tokenize(code: code)

    static func createSpriteDefinitionList() -> MELSpriteDefinitionList {
        var list = MELSpriteDefinitionListMakeWithInitialCapacity(1)
        let definition = MELSpriteDefinition(name: nil, type: MELSpriteTypeDecor, palette: nil, animations: .empty, motionName: nil, loadScript: nil)
        MELSpriteDefinitionListPush(&list, definition)
        return list
    }

    static var previews: some View {
        GeneratedCodeView(tokens: $tokens, selectedFile: .constant(GeneratedFile.code), sprites: createSpriteDefinitionList(), definitionIndex: .constant(0))
            .frame(height: 3000)
    }
}
