//
//  Button.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/** Un bouton switch est seulement Draggable, pas Actionnable.
 * Par contre il y a tout de même la méthode "action" qui doit être overridé.
 * L'action a lieu lors du drag. (ou du "justTouch") */
class SwitchButton : Node, Draggable {
    private var back: TiledSurface!
    private var nub: TiledSurface!
    var isOn: Bool
    
    init(_ refNode: Node?, isOn: Bool,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0) {
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
		letGo(speed: nil)
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
    func letGo(speed: Vector2?) {
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
