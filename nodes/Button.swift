//
//  Button.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/** Classe de base pour les boutons. Un bouton est un noeud sélectionnable
 * (avec les flags selectable/selectableRoot) ayant la méthode "action()" qui doit être overridé. */
class Button : Node {
    init(_ refNode: Node?,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0)
    {
        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags)
        makeSelectable()
    }
    init(_ refNode: Node?,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0)
    {
        super.init(refNode, x, y, width, height, lambda: lambda, flags: flags)
        makeSelectable()
    }
    required init(other: Node) {
        super.init(other: other)
        makeSelectable()
    }
    
    func action() {
        printerror("To be overridden.")
    }
}

// Protocol general de passer au-dessus d'un noeud
protocol Hoverable : Node {
    func startHovering()
    func stopHovering()
    /// Crée un popover
    func showPopMessage()
    /// Met à jour la string à afficher dans le popover. En mode static, crée le noeud popover.
    func setPopString(_ newStrTex: Texture?)
}

// Hoverable avec pop-over
// implémentation par défaut de Hoverable : Un simple FramedString qui apparaît au dessus.
fileprivate protocol HoverablePopover : Hoverable {
    /// La texture du texte popover.
    var popStringTex: Texture? { get set }
    /// La texture du frame du texte popover.
    var popFrameTex: Texture { get }
    /// Le timer pour afficher le popover.
    var popTimerWeak: Timer? { get set }
    /// Le noeud du popover.
    var popMessageWeak: PopMessage? { get set }
    /// Le noeud du popover version static / iOS.
    var framedStringWeak: FramedString? { get set }
    /// Reste afficher dans iOS.
    var iosStatic: Bool { get }
    /// Est en fait dans le front-screen.
    var popInScreen: Bool { get }
}

extension HoverablePopover {
    func startHovering() {
        // (pas encore de popMessage)
        guard popMessageWeak == nil else { return }
        popTimerWeak?.invalidate()
        popTimerWeak = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false)
        { [weak self] _ in
            guard let self = self else { return }
            self.showPopMessage()
        }
    }
    func stopHovering() {
        popTimerWeak?.invalidate()
    }
    func showPopMessage()
    {
        #if os(iOS)
        // Seulement pour iOS : rien à faire en mode "static" (déjà montré)
        // Danc macOS, il faut tout de même faire apparaître le popover même si iosStatic == true.
        if iosStatic {
            return
        }
        #endif
        guard let popStringTex = popStringTex else {
            return
        }
        let height = height.realPos
        let pop = PopMessage(over: self, inScreen: popInScreen,
                   strTex: popStringTex, frameTex: popFrameTex,
                             0, 0.5*height, width: 5*height, height: 0.5*height,
                  fadePos: Vector2(0, -0.3*height), fadeScale: Vector2(-0.15, -0.15),
                  appearTime: 0.1, disappearTime: 2.5)
        self.popMessageWeak = pop
    }
    func setPopString(_ newStrTex: Texture?)
    {
        popStringTex = newStrTex
        #if os(iOS)
        if iosStatic, let newStrTex = newStrTex {
            if let framedString = framedStringWeak {
                framedString.stringSurf.updateStringTexture(newStrTex)
            } else {
                let height = height.realPos
                framedStringWeak = FramedString(self, strTex: newStrTex, frameTex: popFrameTex,
                                                0, 0.5*height, width: 5*height, height: 0.5*height)
            }
        } else {
            framedStringWeak?.disconnect()
        }
        #endif
    }
}

class ButtonHoverable : Button, HoverablePopover {
    fileprivate var popStringTex: Texture?
    fileprivate let popFrameTex: Texture
    fileprivate weak var popTimerWeak: Timer?
    fileprivate weak var popMessageWeak: PopMessage?
    fileprivate weak var framedStringWeak: FramedString?
    fileprivate let iosStatic: Bool
    fileprivate let popInScreen: Bool
    
    init(_ refNode: Node?,
         iosStatic: Bool, popInScreen: Bool, popFrameTex: Texture,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float,
         lambda: Float, flags: Int)
    {
        self.iosStatic = iosStatic
        self.popInScreen = popInScreen
        self.popFrameTex = popFrameTex
        super.init(refNode, x, y, width, height, lambda: lambda, flags: flags)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    override func action() {
        popTimerWeak?.invalidate()
    }
}

/** Pour les noeuds "déplaçable".
* 1. On prend le noeud : "grab",
* 2. On le déplace : "drag",
* 3. On le relâche : "letGo".
* Les position sont dans le référentiel du Draggable.
* On utilise les flags selectable et selectableRoot pour les trouver.
* (On peut être draggable mais pas actionable, e.g. le sliding menu.) */
protocol Draggable : Node {
    func grab(relPosInit: Vector2)
    func drag(relPos: Vector2)
    func letGo() // (iOS ne fournit pas la vitesse)
}

class SecureButton : Node, Draggable {
    private weak var pop_disk: PopDisk? = nil
    private var isHolding: Bool = false
    private let holdTimeSec: Float
    private var disk_timer: Timer? = nil
    private let popTex: Texture
    private let popI: Int
    private let failPopStringTex: Texture
    private let failPopFrameTex: Texture
    private let failPopRatio: Float
    var discDown: Bool = false
    
    init(_ refNode: Node?,
         holdTimeInSec: Float, popTex: Texture, popI: Int,
         failPopStringTexture: Texture,
         failPopFrameTexture: Texture,
         failPopRatio: Float = 0.65,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0)
    {
        self.holdTimeSec = holdTimeInSec
        self.popTex = popTex
        self.popI = popI
        self.failPopStringTex = failPopStringTexture
        self.failPopFrameTex = failPopFrameTexture
        self.failPopRatio = failPopRatio
        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags)
        makeSelectable()
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    func action() {
        printerror("To be overridden.")
    }
    
    func grab(relPosInit posInit: Vector2) {
        let h = height.realPos
        if let disk = pop_disk {
            disk.disconnect()
        }
        let disk = PopDisk(self, pngTex: popTex, deltaT: holdTimeSec, discDown ? 0 : -h/2, 0, h, lambda: 10, i: popI, down: discDown)
        pop_disk = disk
        disk_timer = Timer.scheduledTimer(withTimeInterval: Double(holdTimeSec), repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.pop_disk?.disconnect()
            self.pop_disk = nil
            self.disk_timer = nil
            self.action()
        }
    }
    
    func drag(relPos: Vector2) {
        // (pass)
    }
    
    func letGo() {
        guard let timer = disk_timer else { return }
        pop_disk?.discard() // discard va aussi disconnect le noeud.
        timer.invalidate()
        pop_disk = nil
        disk_timer = nil
        
        let h = height.realPos
        PopMessage(over: self, inScreen: true,
                   strTex: failPopStringTex, frameTex: nil,
                   0, 0.5*h, width: 10*h, height: failPopRatio*h,
                   fadePos: Vector2(0, -0.5*h), fadeScale: Vector2(-0.25, -0.25),
                   appearTime: 0.1, disappearTime: 2.5)
    }
}

class SecureButtonWithPopover : SecureButton, HoverablePopover {
    var popStringTex: Texture?
    let popFrameTex: Texture
    weak var popTimerWeak: Timer?
    weak var popMessageWeak: PopMessage?
    weak var framedStringWeak: FramedString?
    let iosStatic: Bool
    let popInScreen: Bool
    
    init(_ ref: Node?,
         iosStatic: Bool, popInScreen: Bool, popFrameTex: Texture,
         holdTimeInSec: Float, popTex: Texture, popI: Int,
         failPopStringTexture: Texture,
         failPopFrameTexture: Texture,
         failPopRatio: Float = 0.65,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0
    ) {
        self.popFrameTex = popFrameTex
        self.iosStatic = iosStatic
        self.popInScreen = popInScreen
        super.init(ref, holdTimeInSec: holdTimeInSec, popTex: popTex, popI: popI,
                   failPopStringTexture: failPopStringTexture, failPopFrameTexture: failPopFrameTexture,
                   failPopRatio: failPopRatio,
                   x, y, height, lambda: lambda, flags: flags)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    override func action() {
        popTimerWeak?.invalidate()
    }
}

/** Un bouton switch est seulement Draggable, pas Actionnable. (L'action est faite lors de drag ou letgo.)
 * Par contre il y a tout de même la méthode "action" qui doit être overridé.
 * L'action a lieu lors du drag. (ou du "justTouch") */
class SwitchButton : Node, Draggable {
    private var back: TiledSurface!
    private var nub: TiledSurface!
    var isOn: Bool
    private var didDrag = false
    
    init(_ refNode: Node?, isOn: Bool,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0)
	{
        self.isOn = isOn
        super.init(refNode, x, y, 2, 1, lambda: lambda, flags: flags)
        scaleX.set(height)
        scaleY.set(height)
        initStructure()
    }
    required init(other: Node) {
        self.isOn = (other as! SwitchButton).isOn
        super.init(other: other)
        initStructure()
    }
    private func initStructure() {
        makeSelectable()
		
        back = TiledSurface(self, pngTex: Texture.getPng("switch_back"), 0, 0, 1)
        nub = TiledSurface(self, pngTex: Texture.getPng("switch_front"), isOn ? 0.375 : -0.375, 0, 1, lambda: 10)
		
        setBackColor()
    }
	func fix(isOn: Bool) {
		self.isOn = isOn
		nub.x.set(isOn ? 0.375 : -0.375)
		setBackColor()
	}
    func action() {
        printerror("To be overridden.")
    }
    
	func grab(relPosInit posInit: Vector2) {
		didDrag = false
    }
    /** Déplacement en cours du "nub", aura besoin de letGoNub.
    * newX doit être dans le ref. du SwitchButton.
    * Effectue l'action si changement d'état. */
    func drag(relPos: Vector2) {
        // 1. Ajustement de la position du nub.
        nub.x.pos = min(max(relPos.x, -0.375), 0.375)
        // 2. Vérif si changement
        if isOn != (relPos.x > 0) {
            isOn = relPos.x > 0
            setBackColor()
            action()
        }
        didDrag = true
    }
    
    /** Ne fait que placer le nub comme il faut. (À faire après avoir dragué.) */
    func letGo() {
        if !didDrag { // suppose simple touche pour permuter
            isOn = !isOn
            setBackColor()
            action()
        }
        nub.x.pos = isOn ? 0.375 : -0.375
    }
    
    private func setBackColor() {
        if(isOn) {
            back.piu.color = Color.green_electric
        } else {
            back.piu.color = Color.red_vermilion
        }
    }
}

/// Une switch qui ne marche pas (grayed out)
class DummySwitchButton : Button {
    override init(_ refNode: Node?,
         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0, flags: Int = 0)
    {
        super.init(refNode, x, y, 2, 1, lambda: lambda, flags: flags)
        scaleX.set(height)
        scaleY.set(height)
        
        TiledSurface(self, pngTex: Texture.getPng("switch_back"), 0, 0, 1
        ).piu.color = Color.gray2
        TiledSurface(self, pngTex: Texture.getPng("switch_front"), 0, 0, 1
        ).piu.color = Color.gray3
    }
    required init(other: Node) {
        super.init(other: other)
        TiledSurface(self, pngTex: Texture.getPng("switch_back"), 0, 0, 1
        ).piu.color = Color.gray2
        TiledSurface(self, pngTex: Texture.getPng("switch_front"), 0, 0, 1
        ).piu.color = Color.gray3
    }
}

class SliderButton : Node, Draggable {
	// value entre 0 et 1.
	private(set) var value: Float
	private var nub: TiledSurface!
	private let slideWidth: Float
    private let actionAtLetGo: Bool // Action apportée seulement à la fin quand on lâche le nub.
        // Sinon action en continu...
	
    init(parent: Node?, value: Float, actionAtLetGo: Bool,
		 _ x: Float, _ y: Float, _ height: Float, slideWidth: Float,
		 lambda: Float = 0, flags: Int = 0)
	{
		self.slideWidth = max(slideWidth, height)
		self.value = value
        self.actionAtLetGo = actionAtLetGo
		super.init(parent, x, y, self.slideWidth + height, height,
				   lambda: lambda, flags: flags)
		initStructure()
	}
	required init(other: Node) {
		let otherSlider = other as! SliderButton
		self.value = otherSlider.value
		self.slideWidth = otherSlider.slideWidth
        self.actionAtLetGo = otherSlider.actionAtLetGo
		super.init(other: other)
		initStructure()
	}
	private func initStructure() {
		makeSelectable()
		
        Bar(parent: self, framing: .outside, delta: 0.25 * height.realPos, width: slideWidth, texture:
                Texture.getPng("bar_in"))
		
		let xPos = (value - 0.5) * slideWidth
		
		nub = TiledSurface(self, pngTex: Texture.getPng("switch_front"),
                           xPos, 0, height.realPos, lambda: 20)
	}
	
	func grab(relPosInit: Vector2) {
		// (pass)
	}
	
	func drag(relPos: Vector2) {
		// 1. Ajustement de la position du nub.
		nub.x.pos = min(max(relPos.x, -slideWidth/2), slideWidth/2)
		value = nub.x.realPos / slideWidth + 0.5
		// 2. Action!
        if !actionAtLetGo {
            action()
        }
	}
	func action() {
		printerror("To be overridden.")
	}
	
	func letGo() {
        if actionAtLetGo {
            action()
        }
	}
}
