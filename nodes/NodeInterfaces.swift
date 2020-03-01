//
//  NodeInterfaces.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-31.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

protocol KeyboardKey {
    var scancode: Int { get }
    var keycode: Int { get }
    var keymode: Int { get }
    var isVirtual: Bool { get }
}

struct KeyData : KeyboardKey {
    var scancode: Int
    var keycode: Int
    var keymode: Int
    var isVirtual: Bool
}

protocol Openable : Node {
    func open()
}

protocol Closeable : Node {
    func close()
}

/** Pour les noeuds "déplaçable".
* 1. On prend le noeud : "grab",
* 2. On le déplace : "drag",
* 3. On le relâche : "letGo".
* Retourne s'il y a une "action / event".
* On utilise les flags selectable et selectableRoot pour les trouver.
* (On peut être draggable mais pas actionable, e.g. le sliding menu.) */
protocol Draggable : Node {
    func grab(posInit: Vector2) -> Bool
    func drag(posNow: Vector2) -> Bool
    func letGo(speed: Vector2?) -> Bool
}


/** Un noeud pouvant être activé (e.g. les boutons).
* On utilise les flags selectable et selectableRoot pour les trouver. */
protocol Actionable : Node {
    func action()
}

/** Un noeud pouvant être reshapé (e.g. un screen).
* (Reshape: ajustement des positions/dimensions en fonction du cadre du parent).
* Un noeud reshapable doit être dans une classe descendante de SearchableNode.
* On utilise les flags reshapable et reshapableRoot pour les trouver.
* Return: True s'il y a eu changement du cadre, i.e. besoin d'un reshape pour les enfants. */
protocol Reshapable : Node {
    func reshape() -> Bool
}

protocol Fading : Openable, Closeable {}
extension Fading {
    func open() {
        open_fading()
    }
    func close() {
        x.fadeOut()
    }
    // Version "static" de open()
    // (open() est dynamique, i.e. sera overridé en cas de conflit...)
    func open_fading() {
        x.fadeIn()
    }
}

// Incompatible avec Fading (les deux utilisent defPos de manière différente)
// Au pire faire une structure du type (node,RelativeToParent) -> (node,Fading).
protocol RelativeToParent : Reshapable, Openable {}
extension RelativeToParent {
    func reshape() -> Bool {
        setRelativelyToParent(isOpening: false)
        return false
    }
    func open() {
        setRelativelyToParent(isOpening: true)
    }
    func setRelativelyToParent(isOpening: Bool) {
        guard let theParent = parent else {return}
        var xDec: Float = 0
        var yDec: Float = 0
        if (containsAFlag(Flag1.relativeToRight)) {
            xDec = theParent.width.realPos * 0.5
        } else if (containsAFlag(Flag1.relativeToLeft)) {
            xDec = -theParent.width.realPos * 0.5
        }
        if (containsAFlag(Flag1.relativeToTop)) {
            yDec = theParent.height.realPos * 0.5
        }
        x.setRelToDef(shift: xDec, fix: isOpening)
        y.setRelToDef(shift: yDec, fix: isOpening)
    }
}
