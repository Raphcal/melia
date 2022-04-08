//
//  OpenGLView.swift
//  Malice
//
//  Created by Raphaël Calabro on 14/12/2021.
//

import SwiftUI
import MeliceFramework

struct OpenGLView<R: Renderer> {
    typealias ScrollListener = (_ motion: MELSize) -> Void

    let renderer: R
    let rendererContext: R.Context

    var scrollListener: ScrollListener? = nil
    var gestureListener: GestureListener = NoGestureListener()

    func onScroll(_ listener: @escaping ScrollListener) -> OpenGLView {
        var openGLView = self
        openGLView.scrollListener = listener
        return openGLView
    }

    func onGesture(_ listener: GestureListener) -> OpenGLView {
        var openGLView = self
        openGLView.gestureListener = listener
        return openGLView
    }
}
