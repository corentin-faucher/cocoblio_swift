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
    var isSuspended: Bool = true {
        didSet {
            isPaused = isSuspended
        }
    }
    override var isPaused: Bool {
        didSet {
            if isSuspended, !isPaused { // Ne peut sortir de pause si l'activité est suspendu...
                printwarning("unpause while suspended...")
                isPaused = true
                return
            }
            GlobalChrono.isPaused = isPaused
        }
    }
    
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        printdebug("Init MetalView")
        device = MTLCreateSystemDefaultDevice()
        renderer = Renderer(metalView: self, withDepth: false)
        renderer.initClearColor(rgb: Color.blue_azure)
        delegate = renderer
        
        root = AppRootBase(view: self)
        Texture.pngNameToTiling.putIfAbsent(key: "tiles_sol", value: (8, 9))
        TiledSurface(root, pngTex: Texture.defaultPng, 0, 0, 1, flags: Flag1.show)
        
        Platforme(root, tex: Texture.getPng("tiles_sol"), n: 100, 0, 0, 5).also {
            $0.openAndShowBranch()
        }
    }
    
    func setBackground(color: Vector4, isDark: Bool) {
        renderer.updateClearColor(rgb: color)
    }
    
    func addScrollingViewIfNeeded(with slidingMenu: SlidingMenu) {
        // pass
    }
    
    func removeScrollingView() {
        // pass
    }
    
    
}
