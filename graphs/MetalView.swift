//
//  MetalView.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-12.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import MetalKit

// Devrait être spécifique au projet...?

class MetalView: MTKView {
    var renderer: Renderer!
    var trackingArea: NSTrackingArea?
    var eventsHandler: EventsHandler!
    var isTransitioning: Bool = false
    
    func touch() {
        isPaused = false
        GlobalChrono.isPaused = false
    }
    
    func pause() {
        isPaused = true
        GlobalChrono.isPaused = true
    }
    
    override func awakeFromNib() {
        print("awake MetalView")
        guard let window = self.window else {
            printerror("Pas de fenêtre attachée."); return
        }
        window.makeFirstResponder(self)
//        window.contentAspectRatio = NSSize(width: 16, height: 10)
        
        NotificationCenter.default.addObserver(forName: NSWindow.willEnterFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.pause()
            window.resizeIncrements = NSSize(width: 1, height: 1)
            print("will enter fullScreen.")
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.touch()
            print("did enter fullScreen.(set keyStore)")
        }
        NotificationCenter.default.addObserver(forName: NSWindow.willExitFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.pause()
            print("will exit fullscreen")
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didExitFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.touch()
//            window.contentAspectRatio = NSSize(width: 16, height: 10)
            print("did exit fullscreen.")
        }
        
        renderer.setFrameFromViewSize(bounds.size, justSetFullFrame: false)
        
        eventsHandler.appStart()
        
        print("fin awake MetalView")
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        renderer = Renderer(metalView: self)
    }
    override func updateTrackingAreas() {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea!)
        }
        let options: NSTrackingArea.Options =
            [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
//        print("MV mouseEntered.")
        //        NSCursor.hide()
    }
    override func mouseExited(with event: NSEvent) {
//        print("MV mouseExited.")
//        NSCursor.unhide()
    }
    override func mouseMoved(with event: NSEvent) {
        touch()
    }
    override func mouseDown(with event: NSEvent) {
        touch()
        eventsHandler?.singleTap(pos: renderer.getPositionFrom(event.locationInWindow, viewSize: bounds.size, invertedY: false))
    }
    override func keyUp(with event: NSEvent) {
        touch()
        eventsHandler?.keyUp(key:
            KeyData(scancode: Int(event.keyCode), keycode: Int(event.keyCode),
                    keymode: Int(event.modifierFlags.rawValue), isVirtual: false))
    }
    override func keyDown(with event: NSEvent) {
        touch()
        eventsHandler?.keyDown(key:
            KeyData(scancode: Int(event.keyCode), keycode: Int(event.keyCode),
                    keymode: Int(event.modifierFlags.rawValue), isVirtual: false))
    }
}
