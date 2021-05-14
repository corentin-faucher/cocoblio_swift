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
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    func action() {
        printerror("To be overridden.")
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
    private var disk: PopDisk? = nil
    private var isHolding: Bool = false
    private var countdown: CountDown
    private var timer: Timer? = nil
    private let popTex: Texture
    private let popI: Int
    private let failPopStringTex: Texture
    private let failPopFrameTex: Texture
    private unowned let screen: ScreenBase
    
    init(_ refNode: Node?,
         holdTimeInSec: Float, popTex: Texture, popI: Int,
         failPopStringTexture: Texture, failPopFrameTexture: Texture, screen: ScreenBase,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0)
    {
        self.popTex = popTex
        self.popI = popI
        self.countdown = CountDown(ringSec: holdTimeInSec)
        self.failPopStringTex = failPopStringTexture
        self.failPopFrameTex = failPopFrameTexture
        self.screen = screen
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
        countdown.start()
        let h = height.realPos
        if let disk = disk {
            disk.disconnect()
        }
        disk = PopDisk(self, pngTex: popTex, deltaT: countdown.ringTimeSec, -h/2, 0, h, lambda: 10, i: popI)
        timer = Timer.scheduledTimer(withTimeInterval: Double(countdown.ringTimeSec), repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.disk?.disconnect()
            self.timer = nil
            self.action()
        }
    }
    
    func drag(relPos: Vector2) {
        // (pass)
    }
    
    func letGo() {
        guard let timer = timer else { return }
        disk?.discard() // discard va aussi disconnect le noeud.
        disk = nil
        timer.invalidate()
        let (pos, delta) = self.getAbsPosAndDelta()
        PopMessage(parent: screen, strTex: failPopStringTex, frameTex: failPopFrameTex,
                   pos.x, pos.y + 1.5*delta.y, 0.1, appearTime: 0.1, disappearTime: 2, fadeInY: -2*delta.y)
    }
}

/** Un bouton switch est seulement Draggable, pas Actionnable. (L'action est faite lors de drag ou letgo.)
 * Par contre il y a tout de même la méthode "action" qui doit être overridé.
 * L'action a lieu lors du drag. (ou du "justTouch") */
class SwitchButton : Node, Draggable {
    private var back: TiledSurface!
    private var nub: TiledSurface!
    var isOn: Bool
    var didDrag = false
    
    init(_ refNode: Node?, isOn: Bool,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0)
	{
        self.isOn = isOn
        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags)
        scaleX.set(height)
        scaleY.set(height)
        self.height.set(1)
        width.set(2)
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
            back.piu.color = [0.2, 1, 0.5, 1]
        } else {
            back.piu.color = [1, 0.3, 0.1, 1]
        }
    }
}

class SliderButton : Node, Draggable {
	// value entre 0 et 1.
	private(set) var value: Float
	private var nub: TiledSurface!
	private let slideWidth: Float
    private let actionAtLetGo: Bool // Action apportée seulement à la fin quand on lâche le nub.
        // Sinon action en continu...
	
    init(parent: Node, value: Float, actionAtLetGo: Bool,
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
