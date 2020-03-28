//
//  Button.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

class SwitchButton : Node, Actionable, Draggable {
    private var back: TiledSurface!
    private var nub: TiledSurface!
    private var isOn: Bool
    
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
		back = TiledSurface(self, pngTex: Texture.getExistingPng("switch_back"), 0, 0, 1)
		nub = TiledSurface(self, pngTex: Texture.getExistingPng("switch_front"), isOn ? 0.375 : -0.375, 0, 1, lambda: 10)
        setBackColor()
    }
    
    func action() {
        printerror("Empty switchButton! (override...)")
    }
    
    func fix(isOn: Bool) {
        self.isOn = isOn
        nub.x.set(isOn ? 0.375 : -0.375)
        setBackColor()
    }
    /** Simple touche. Permute l'état présent (n'effectue pas l'"action") */
    func justTapNub() {
        isOn = !isOn
        setBackColor()
        letGo(speed: nil)
    }
    
    func grab(posInit: Vector2) -> Bool {
        return false
    }
    /** Déplacement en cours du "nub", aura besoin de letGoNub.
    * newX doit être dans le ref. du SwitchButton.
    * Retourne true si l'état à changer (i.e. action requise ?) */
    func drag(posNow: Vector2) -> Bool {
        // 1. Ajustement de la position du nub.
        nub.x.pos = min(max(posNow.x, -0.375), 0.375)
        // 2. Vérif si changement
        if isOn != (posNow.x > 0) {
            isOn = posNow.x > 0
            setBackColor()
            return true
        }
        return false
    }
    
    /** Ne fait que placer le nub comme il faut. (À faire après avoir dragué.) */
    @discardableResult
    func letGo(speed: Vector2?) -> Bool {
        nub.x.pos = isOn ? 0.375 : -0.375
        return false
    }
    
    private func setBackColor() {
        if(isOn) {
            back.piu.color = [0.2, 1, 0.5, 1]
        } else {
            back.piu.color = [1, 0.3, 0.1, 1]
        }
    }
}
