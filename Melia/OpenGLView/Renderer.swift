//
//  Renderer.swift
//  Malice
//
//  Created by Raphaël Calabro on 20/10/2021.
//

import Foundation
import MeliceFramework

protocol Renderer {
    associatedtype Context: RendererContext

    func setup()
    func shutdown()
    func renderFrame(context: Context)
    func update(elasped time: TimeInterval)
}

protocol RendererContext: Equatable {
    static var empty: Self { get }
}

extension Renderer {
    func setup() {
        // Vide
    }
    func shutdown() {
        // Vide
    }
    func renderFrame(context: Context) {
        // Vide
    }
    func update() {
        // Vide
    }
}

struct NoRenderer: Renderer {
    struct Context: RendererContext {
        static let empty = Context()
    }
}
