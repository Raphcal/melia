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
    let definition: MELSpriteDefinition

    @State private var headerFile: String = ""
    @State private var codeFile: String = ""

    var body: some View {
        ScrollView {
            Text(selectedFile == .header
                 ? headerFile
                 : codeFile)
            .textSelection(.enabled)
            .font(.custom("Fira Code", size: 12))
            .padding(4)
        }
        .onChange(of: tokens) { tokens in
            let generator = PlaydateCodeGenerator(tree: TokenTree(tokens: tokens), for: definition)
            self.headerFile = generator.headerFile
            self.codeFile = generator.codeFile
        }
    }
}
