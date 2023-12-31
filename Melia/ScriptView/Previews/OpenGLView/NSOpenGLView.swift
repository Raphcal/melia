//
//  OpenGLView.swift
//  Malice
//
//  Created by Raphaël Calabro on 12/03/2021.
//

import SwiftUI
import OpenGL
import MeliceFramework

extension OpenGLView: NSViewRepresentable {
    func makeNSView(context: Context) -> MELOpenGLView {
        let pixelFormat = NSOpenGLPixelFormat(attributes: [
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAColorSize, 32,
            NSOpenGLPFAAlphaSize, 16,
            0].map { value in NSOpenGLPixelFormatAttribute(value) })
        let view = MELOpenGLView(frame: CGRect.zero, pixelFormat: pixelFormat)!
        view.scrollListener = scrollListener
        view.gestureListener = gestureListener

        guard let openGLContext = view.openGLContext else {
            NSLog("Unable to get an OpenGL context from NSOpenGLView")
            return MELOpenGLView()
        }

        openGLContext.setValues([1], for: NSOpenGLContext.Parameter.swapInterval)
        view.prepareOpenGL()

        let coordinator = context.coordinator
        coordinator.openGLView = view
        coordinator.initializeDisplayLink()
        coordinator.runInOpenGLContext {
            MELRendererInit()
            coordinator.renderer.load(context: rendererContext)
            coordinator.startDisplayLink()
        }

        if gestureListener is NoGestureListener {
            view.gestureListener = coordinator.renderer
        }

        view.willDrawListener = {
            coordinator.renderFrame()
            view.willDrawListener = nil
        }

        return view
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(rendererContext: rendererContext)
    }

    func updateNSView(_ nsView: MELOpenGLView, context: Context) {
        let coordinator = context.coordinator

        if gestureListener is NoGestureListener {
            nsView.gestureListener = coordinator.renderer
        } else {
            nsView.gestureListener = gestureListener
        }
        if gestureListener.listenToMoves != (coordinator.mouseMoveMonitor != nil) {
            listenToMouseMoveEvents(of: nsView, coordinator: coordinator)
            return
        }

        if coordinator.rendererContext != rendererContext {
            coordinator.runInOpenGLContext {
                coordinator.renderer.load(context: rendererContext)
            }
        }
        coordinator.rendererContext = rendererContext
        coordinator.updateAndRenderFrame(elapsed: 0)
    }

    func listenToMouseMoveEvents(of nsView: MELOpenGLView, coordinator: Coordinator) {
        if gestureListener.listenToMoves && coordinator.mouseMoveMonitor == nil {
            coordinator.mouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
                let frame = nsView.frame
                var point = nsView.convert(event.locationInWindow, from: nil)
                point.y = nsView.frame.height - point.y
                if point.x >= 0 && point.x < frame.width && point.y >= 0 && point.y < frame.height {
                    nsView.gestureListener.onMove(to: MELIntPoint(point))
                }
                return event
            }
        } else if let mouseMoveMonitor = coordinator.mouseMoveMonitor,  !gestureListener.listenToMoves {
            NSEvent.removeMonitor(mouseMoveMonitor)
            coordinator.mouseMoveMonitor = nil
        }
    }

    class Coordinator {
        weak var openGLView: MELOpenGLView?
        var renderer = Renderer()
        var rendererContext: RendererContext
        var mouseMoveMonitor: Any?
        var displayLink: CVDisplayLink?

        var frameSize: MELSize {
            return MELSize(openGLView?.frame.size ?? CGSize(width: 32, height: 32))
        }

        init(rendererContext: RendererContext) {
            self.rendererContext = rendererContext
        }

        deinit {
            stopDisplayLink()
            runInOpenGLContext {
                renderer.unload()
            }
            if let mouseMoveMonitor = mouseMoveMonitor {
                NSEvent.removeMonitor(mouseMoveMonitor)
            }
        }

        func initializeDisplayLink() {
            guard let openGLContext = openGLView?.openGLContext,
                  let cglContextObj = openGLContext.cglContextObj,
                  let cglPixelFormatObj = openGLContext.pixelFormat.cglPixelFormatObj
            else {
                print("initializeDisplayLink: No OpenGLContext")
                return
            }

            var swapInt: GLint = 1
            openGLContext.setValues(&swapInt, for: NSOpenGLContext.Parameter.swapInterval)

            CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)

            guard let displayLink = displayLink else {
                print("initializeDisplayLink: No displayLink or cglContextObj or cglPixelFormatObj")
                return
            }

            CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContextObj, cglPixelFormatObj)

            CVDisplayLinkSetOutputHandler(displayLink, { [weak self] (displayLink, now, outputTime, flagsIn, flagsOut) -> CVReturn in
                let time = TimeInterval(outputTime.pointee.videoTime) / TimeInterval(outputTime.pointee.videoTimeScale)
                self?.updateAndRenderFrame(elapsed: time)
                return kCVReturnSuccess
            })
        }

        func startDisplayLink() {
            guard let displayLink = displayLink else {
                return
            }
            CVDisplayLinkStart(displayLink)
        }
        func stopDisplayLink() {
            guard let displayLink = displayLink else {
                return
            }
            CVDisplayLinkStop(displayLink)
        }

        func updateAndRenderFrame(elapsed time: TimeInterval) {
            runInOpenGLContext {
                renderer.update(elasped: time)
                renderer.renderFrame(size: frameSize)
            }
        }

        func renderFrame() {
            runInOpenGLContext {
                renderer.renderFrame(size: frameSize)
            }
        }

        func runInOpenGLContext(_ block: () -> Void) {
            guard let openGLContext = openGLView?.openGLContext else {
                NSLog("No openGLContext")
                if let displayLink = displayLink {
                    CVDisplayLinkStop(displayLink)
                }
                displayLink = nil
                return
            }
            if Thread.isMainThread {
                openGLContext.makeCurrentContext()
                openGLContext.lock()
                block()
                openGLContext.flushBuffer()
                openGLContext.unlock()
            } else {
                DispatchQueue.main.sync {
                    openGLContext.makeCurrentContext()
                    openGLContext.lock()
                    block()
                    openGLContext.flushBuffer()
                    openGLContext.unlock()
                }
            }
        }
    }
}

class MELOpenGLView: NSOpenGLView {
    var scrollListener: OpenGLView.ScrollListener? = nil
    var gestureListener: GestureListener = NoGestureListener()
    var willDrawListener: (() -> Void)? = nil

    var dragStartLocation: MELIntPoint?

    override func viewWillDraw() {
        willDrawListener?()
    }

    override func scrollWheel(with event: NSEvent) {
        scrollListener?(MELSize(width: GLfloat(event.scrollingDeltaX), height:  GLfloat(event.scrollingDeltaY)))
    }

    override func mouseDown(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let localPoint = convert(locationInWindow, from: nil)
        let location = MELIntPoint(x: Int32(localPoint.x), y: Int32(frame.height - localPoint.y))
        self.dragStartLocation = location
        gestureListener.onTap(at: location, isPrimary: true)
    }
    override func rightMouseDown(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let localPoint = convert(locationInWindow, from: nil)
        let location = MELIntPoint(x: Int32(localPoint.x), y: Int32(frame.height - localPoint.y))
        gestureListener.onTap(at: location, isPrimary: false)
    }
    override func mouseDragged(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let localPoint = convert(locationInWindow, from: nil)
        let location = MELIntPoint(x: Int32(localPoint.x), y: Int32(frame.height - localPoint.y))
        gestureListener.onDrag(from: dragStartLocation!, to: location)
    }
    override func mouseUp(with event: NSEvent) {
        dragStartLocation = nil
        gestureListener.onDragEnd()
    }
}
