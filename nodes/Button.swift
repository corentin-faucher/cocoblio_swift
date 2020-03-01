//
//  Button.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/** Classe de base des boutons.
 * Par défaut un bouton n'est qu'un carré sans surface.
 * Un bouton n'est qu'un SearchableNode (selectable) avec action (Actionable). */
class Button : Node, Actionable {
    init(_ refNode: Node?, _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0) {
        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags)
        makeSelectable()
    }
    required internal init(refNode: Node?, toCloneNode: Node, asParent: Bool = true, asElderBigbro: Bool = false) {
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
        makeSelectable()
    }
    func action() {
        printerror("Empty button! (override...)")
    }
}

class SwitchButton : Node, Actionable, Draggable {
    private var back: Surface!
    private var nub: Surface!
    private var isOn: Bool
    
    init(_ refNode: Node?, isOn: Bool,
         _ x: Float, _ y: Float, _ height: Float,
         lambda: Float = 0, flags: Int = 0) {
        self.isOn = isOn
        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags)
        makeSelectable()
        scaleX.set(height)
        scaleY.set(height)
        self.height.set(1)
        width.set(2)
        back = Surface(self, pngID: "switch_back", 0, 0, 1)
        nub = Surface(self, pngID: "switch_front", isOn ? 0.375 : -0.375, 0, 1, lambda: 10)
        setBackColor()
    }
    
    required internal init(refNode: Node?, toCloneNode: Node,
                           asParent: Bool = true, asElderBigbro: Bool = false) {
        self.isOn = (toCloneNode as! SwitchButton).isOn
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
        makeSelectable()
        back = Surface(self, pngID: "switch_back", 0, 0, 1)
        nub = Surface(self, pngID: "switch_front", isOn ? 0.375 : -0.375, 0, 1, lambda: 10)
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
