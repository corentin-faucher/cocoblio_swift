//
//  MetalViewIOS.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-03-10.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import MetalKit

class MetalView : MTKView {
    var renderer: Renderer!
    var eventsHandler: EventsHandler!
    var isTransitioning: Bool = false
    
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        renderer = Renderer(metalView: self)
    }
    
    override func awakeFromNib() {
        print("awakeFromNib. size: \(bounds.size)")
        renderer.setFrameFromViewSize(bounds.size, justSetFullFrame: false)
        eventsHandler.appStart()
    }
    
    func touch() {
        isPaused = false
        GlobalChrono.isPaused = false
    }
    
    func pause() {
        isPaused = true
        GlobalChrono.isPaused = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        eventsHandler.singleTap(pos: renderer.getPositionFrom(location, viewSize: bounds.size,
                                                              invertedY: true))
    }
    
}
