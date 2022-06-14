//
//  TestMetalView.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-02-03.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import MetalKit
import GameController

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
            AppChrono.isPaused = isPaused
            RenderingChrono.isPaused = isPaused
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
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidBecomeCurrent, object: nil, queue: nil) { [self] _ in
            guard let controller = GCController.current, let root = self.root as? AppRoot, let bonhomme = root.bonhomme else {
                printerror("no controller or no root?"); return
            }
            print("🐱 Controller current detected \(controller.debugDescription)")
            if let motion = controller.motion {
                print("Motion found")
                motion.valueChangedHandler = { (motion: GCMotion) in
                    print("motion \(motion)")
                }
            }
            if let haptics = controller.haptics {
                print("haptic \(haptics.supportedLocalities)")
//                haptics.createEngine(withLocality: .handles)
            }
            guard let gamepad = controller.extendedGamepad else {
                printerror("No gamepad"); return
            }
            gamepad.rightTrigger.pressedChangedHandler = { (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self.isPaused = false
                bonhomme.action(x: gamepad.rightThumbstick.xAxis.value, y: gamepad.rightThumbstick.yAxis.value, speed: 5)
            }
            gamepad.leftThumbstick.valueChangedHandler = { (direct: GCControllerDirectionPad, x: Float, y: Float) in
                self.isPaused = false
                bonhomme.acc.x = 2*x
                bonhomme.acc.y = 2*y
                print("leftThumbStick : \(x), \(y).")
            }
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
    
    override func mouseMoved(with event: NSEvent) {
        self.isPaused = false
    }
    override func mouseDown(with event: NSEvent) {
        self.isPaused = false
    }
    
    override func keyDown(with event: NSEvent) {
        if let controller = GCController.current {
            print("Controller \(controller.battery?.batteryLevel ?? 0)")
            if let gamepat = controller.extendedGamepad {
                print("button a \(gamepat.buttonA.isPressed)")
            }
        }
        print("Controller \(GCController.controllers())")
        self.isPaused = false
//        let key = KeyData(keycode: event.keyCode, keymod: event.modifierFlags.rawValue, isVirtual: false, char: event.characters?.first)
//        keyAction(key: key)
        guard let root = root as? AppRoot, let bonhomme = root.bonhomme else {
            printerror("bad root")
            return
        }
        switch event.keyCode {
            case Keycode.leftArrow:
                bonhomme.acc.x = -1
            case Keycode.rightArrow:
                bonhomme.acc.x = 1
            case Keycode.upArrow:
                bonhomme.acc.y = 1
            case Keycode.downArrow:
                bonhomme.acc.y = -1
            case Keycode.space:
                bonhomme.action(x: 0, y: 0, speed: 2)
            default: break
        }
    }
    override func keyUp(with event: NSEvent) {
        self.isPaused = false
        guard let root = root as? AppRoot, let bonhomme = root.bonhomme else {
            printerror("bad root")
            return
        }
        switch event.keyCode {
            case Keycode.leftArrow, Keycode.rightArrow:
                bonhomme.acc.x = 0
            case Keycode.upArrow, Keycode.downArrow:
                bonhomme.acc.y = 0
            default: break
        }
    }
}
