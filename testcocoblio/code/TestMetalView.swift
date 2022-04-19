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
        
        device = MTLCreateSystemDefaultDevice()
        renderer = Renderer(metalView: self, withDepth: false)
        renderer.initClearColor(rgb: Color.gray)
        delegate = renderer
    }
    
    override func awakeFromNib() {
        guard let window = self.window else {
            printerror("No window attach to metalview."); return
        }
        
        // A priori, la vue répond aux events.
        window.makeFirstResponder(self)
        
        window.contentAspectRatio = NSSize(width: 16, height: 10)
        
        // Construire la structure de l'app : root. Et vérifier les dimensions.
        root = AppRoot(view: self)
        // Check view dimensions
        let headerHeight = window.styleMask.contains(.fullScreen) ? 22 : window.frame.height - window.contentLayoutRect.height
        root.margins = Margins(top: headerHeight, left: 0, bottom: 0, right: 0)
        root.frameSizeInPx = frame.size
        root.updateFrame()
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
    
    override func mouseMoved(with event: NSEvent) {
        self.isPaused = false
    }
    override func mouseDown(with event: NSEvent) {
        self.isPaused = false
    }
    
    override func keyDown(with event: NSEvent) {
        self.isPaused = false
//        let key = KeyData(keycode: event.keyCode, keymod: event.modifierFlags.rawValue, isVirtual: false, char: event.characters?.first)
//        keyAction(key: key)
        guard let root = root as? AppRoot, let particle = root.particle else {
            printerror("bad root")
            return
        }
        switch event.keyCode {
            case Keycode.leftArrow:
                particle.acc.x = -1
            case Keycode.rightArrow:
                particle.acc.x = 1
            case Keycode.upArrow:
                particle.acc.y = 1
            case Keycode.downArrow:
                particle.acc.y = -1
            default: break
        }
    }
    override func keyUp(with event: NSEvent) {
        self.isPaused = false
        guard let root = root as? AppRoot, let particle = root.particle else {
            printerror("bad root")
            return
        }
        switch event.keyCode {
            case Keycode.leftArrow, Keycode.rightArrow:
                particle.acc.x = 0
            case Keycode.upArrow, Keycode.downArrow:
                particle.acc.y = 0
            default: break
        }
    }
}
