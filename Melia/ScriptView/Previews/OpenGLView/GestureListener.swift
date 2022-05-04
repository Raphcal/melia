//
//  TapListener.swift
//  Malice
//
//  Created by Raphaël Calabro on 19/12/2021.
//

import MeliceFramework

protocol GestureListener {
    var listenToMoves: Bool { get }

    func onTap(at location: MELIntPoint, isPrimary: Bool)
    func onDrag(from: MELIntPoint, to: MELIntPoint)
    func onDragEnd()
    func onMove(to point: MELIntPoint)
}

extension GestureListener {
    var listenToMoves: Bool {
        return false
    }
    func onTap(at location: MELIntPoint, isPrimary: Bool) {
        // Vide
    }
    func onDrag(from: MELIntPoint, to: MELIntPoint) {
        // Vide
    }
    func onDragEnd() {
        // Vide
    }
    func onMove(to point: MELIntPoint) {
        // Vide
    }
}

struct NoGestureListener: GestureListener {
    // Vide
}
