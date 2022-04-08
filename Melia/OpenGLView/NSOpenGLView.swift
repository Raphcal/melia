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
        coordinator.renderer = renderer
        coordinator.runInOpenGLContext {
            renderer.setup()
        }

        

        view.willDrawListener = {
            coordinator.renderFrame()
            view.willDrawListener = nil
        }

        return view
    }

    func makeCoordinator() -> Coordinator<R> {
        return Coordinator(renderer: renderer)
    }

    func updateNSView(_ nsView: MELOpenGLView, context: Context) {
        nsView.gestureListener = gestureListener

        if gestureListener.listenToMoves != (context.coordinator.mouseMoveMonitor != nil) {
            listenToMouseMoveEvents(of: nsView, coordinator: context.coordinator)
            return
        }

        if context.coordinator.rendererContext != rendererContext {
            context.coordinator.rendererContext = rendererContext
        } else {
            renderer.update()
        }
        context.coordinator.renderFrame()
    }

    func listenToMouseMoveEvents(of nsView: MELOpenGLView, coordinator: Coordinator<R>) {
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

    func initializeDisplayLink(coordinator: Coordinator<R>) {
        guard let openGLContext = coordinator.openGLView?.openGLContext,
              let pixelFormat = coordinator.openGLView?.pixelFormat else {
            print("initializeDisplayLink: No OpenGLContext")
            return
        }

        var swapInt: GLint = 1
        openGLContext.setValues(&swapInt, for: NSOpenGLContext.Parameter.swapInterval)

        CVDisplayLinkCreateWithActiveCGDisplays(&coordinator.displayLink)

        CVDisplayLinkSetOutputCallback(coordinator.displayLink!, { (displayLink, now, outputTime, flagsIn, flagsOut, displayLinkContext) -> CVReturn in
            if let renderer = displayLinkContext?.assumingMemoryBound(to: R.self) {
                let time = TimeInterval(outputTime.pointee.videoTime) / TimeInterval(outputTime.pointee.videoTimeScale)
                DispatchQueue.main.sync {
                    renderer.pointee.update(elasped: time)
                }
                return kCVReturnSuccess
            } else {
                return kCVReturnError
            }
        }, &coordinator.renderer)
        
        CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(coordinator.displayLink!, openGLContext.cglContextObj!, pixelFormat.cglPixelFormatObj!)
        
        CVDisplayLinkStart(coordinator.displayLink!)
    }

    class Coordinator<R: Renderer> {
        weak var openGLView: MELOpenGLView?
        var renderer: R
        var rendererContext: R.Context = .empty
        var mouseMoveMonitor: Any?
        var displayLink: CVDisplayLink?

        init(renderer: R) {
            self.renderer = renderer
        }

        deinit {
            runInOpenGLContext {
                renderer.shutdown()
            }
            if let mouseMoveMonitor = mouseMoveMonitor {
                NSEvent.removeMonitor(mouseMoveMonitor)
            }
        }

        func renderFrame() {
            runInOpenGLContext {
                renderer.renderFrame(context: rendererContext)
            }
        }

        func runInOpenGLContext(_ block: () -> Void) {
            guard let openGLContext = openGLView?.openGLContext else {
                NSLog("No openGLContext")
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
