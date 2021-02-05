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
    func justTap()
}

/** Un bouton switch est seulement Draggable, pas Actionnable. (L'action est faite lors de justTap et drag.)
 * Par contre il y a tout de même la méthode "action" qui doit être overridé.
 * L'action a lieu lors du drag. (ou du "justTouch") */
class SwitchButton : Node, Draggable {
    private var back: TiledSurface!
    private var nub: TiledSurface!
    var isOn: Bool
    
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
		
		back = TiledSurface(self, pngTex:
			Texture.tryToGetExistingPng("switch_back") ?? Texture.getNewPng("switch_back", m: 1, n: 1),
			0, 0, 1)
		nub = TiledSurface(self, pngTex:
			Texture.tryToGetExistingPng("switch_front") ?? Texture.getNewPng("switch_front", m: 1, n: 1),
			isOn ? 0.375 : -0.375, 0, 1, lambda: 10)
		
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
    
    /** Simple touche. Permute l'état présent et effectue l'action. */
	func justTap() {
		isOn = !isOn
		setBackColor()
		letGo()
		action()
	}
    
	func grab(relPosInit posInit: Vector2) {
		// (Rien à faire pour SwitchButton)
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
    }
    
    /** Ne fait que placer le nub comme il faut. (À faire après avoir dragué.) */
    func letGo() {
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
		
		Bar(parent: self, framing: .inside, delta: 0.25 * height.realPos, width: slideWidth, texture:
			Texture.tryToGetExistingPng("bar_in") ?? Texture.getNewPng("bar_in", m: 1, n: 1))
		
		let xPos = (value - 0.5) * slideWidth
		
		nub = TiledSurface(self, pngTex:
			Texture.tryToGetExistingPng("switch_front") ?? Texture.getNewPng("switch_front", m: 1, n: 1),
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
	func justTap() {
		// (pass, il faut bouger au moins un peu le slider...)
	}
}
