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
    var eventsHandler: EventsHandler?
    
    
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
//        window.title = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        
        NotificationCenter.default.addObserver(forName: NSWindow.willEnterFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.pause()
            print("will enter fullScreen.")
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.touch()
            print("did enter fullScreen.(set keyStore)")
            AppState.state |= AppState.isFullScreen
            UserDefaults().set(AppState.state, forKey: "AppState")
        }
        NotificationCenter.default.addObserver(forName: NSWindow.willExitFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.pause()
            print("will exit fullscreen")
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didExitFullScreenNotification, object: nil, queue: nil) { (notif) in
            self.touch()
            print("did exit fullscreen.")
            AppState.state &= ~AppState.isFullScreen
            UserDefaults().set(AppState.state, forKey: "AppState")
        }
    }
    
    required init(coder: NSCoder) {
        print("Init MetalView")
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
        print("MV mouseEntered.")
        NSCursor.hide()
    }
    override func mouseExited(with event: NSEvent) {
        print("MV mouseExited.")
        NSCursor.unhide()
    }
    override func mouseMoved(with event: NSEvent) {
        touch()
    }
    override func mouseDown(with event: NSEvent) {
        touch()
        eventsHandler?.singleTap(pos: Renderer.getPositionFrom(event.locationInWindow, invertedY: false))
    }
}
