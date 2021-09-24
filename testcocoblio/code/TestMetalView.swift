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
    var didTransition: Bool = false
    var canPauseWhenResignActive: Bool = true
    var isDarkMode: Bool {
        get {
            switch effectiveAppearance.name {
                case .darkAqua, .vibrantDark,
                     .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                    return true
                default:
                    return false
            }
        }
    }
    
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        printdebug("Init MetalView")
        device = MTLCreateSystemDefaultDevice()
        renderer = Renderer(metalView: self, withDepth: false)
        renderer.initClearColor(rgb: [0.2, 0.2, 0.8])
        delegate = renderer
        
        root = AppRootBase(view: self)
        TiledSurface(root, pngTex: Texture.defaultPng, 0, 0, 1, flags: Flag1.show)
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
