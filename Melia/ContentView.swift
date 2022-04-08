//
//  ContentView.swift
//  Melia
//
//  Created by Raphaël Calabro on 02/04/2022.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var document: MeliaDocument
    @State private var code = ""

    var body: some View {
        HStack {
            TextEditor(text: $code)
                .font(.custom("Fira Code", size: 14))
            Rectangle()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: MeliaDocument())
    }
}
