//
//  MeliaApp.swift
//  Melia
//
//  Created by Raphaël Calabro on 02/04/2022.
//

import SwiftUI

@main
struct MeliaApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MeliaDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
