//
//  TestMetalView.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-02-03.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import MetalKit

class MetalView: MTKView, CoqMetalView {
    var root: AppRootBase!
    var renderer: Renderer!
    
    var fullFrame: CGSize = CGSize(width: 2, height: 2)
    var usableFrame: CGRect = CGRect(x: 0, y: 0, width: 2, height: 2)
    var isTransitioning: Bool = false
    var canPauseWhenResignActive: Bool = true
    
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    func setBackground(color: Vector3, isDark: Bool) {
        renderer.updateClearColor(rgb: color)
    }
    
    func addScrollingViewIfNeeded(with slidingMenu: SlidingMenu) {
        // pass
    }
    
    func removeScrollingView() {
        // pass
    }
    
    
}
