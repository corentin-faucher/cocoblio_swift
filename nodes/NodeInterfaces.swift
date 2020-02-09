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


/** Noeuds pouvant être retrouvé dans l'arborescence.
* Doit être utilisé avec les interfaces Dragable, Actionable ou Reshapable.
* rootFlag: identifie les noeud racine pour remontner jusqu'à lui.
* findFlag: signale sa présence (pas besoin pour Reshapable. */
class SearchableNode : Node {
    private let rootFlag: Int
    init(_ refNode: Node?,
                  rootFlag: Int, findFlag: Int,
                  _ x: Float, _ y: Float, _ width: Float, _ height: Float,
                  lambda: Float = 0, flags: Int = 0,
                  asParent: Bool = true, asElderBigbro: Bool = false) {
        self.rootFlag = rootFlag
        super.init(refNode, x, y, width, height, lambda: lambda,
                   flags: flags|findFlag, asParent: asParent, asElderBigbro: asElderBigbro)
        addRootFlag(rootFlag)
    }
    
    required internal init(refNode: Node?, toCloneNode: Node, asParent: Bool = true, asElderBigbro: Bool = false) {
        let toCloneSearchable = toCloneNode as! SearchableNode
        self.rootFlag = toCloneSearchable.rootFlag
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
        addRootFlag(rootFlag)
    }
    
}

/** Un noeud pouvant être activé (e.g. les boutons).
* Un noeud Actionable doit être dans une classe descendante de SearchableNode.
* On utilise les flags selectable et selectableRoot pour les trouver. */
protocol Actionable : SearchableNode {
    func action()
}

/** Un noeud pouvant être reshapé (e.g. un screen).
* (Reshape: ajustement des positions/dimensions en fonction du cadre du parent).
* Un noeud reshapable doit être dans une classe descendante de SearchableNode.
* On utilise les flags reshapable et reshapableRoot pour les trouver.
* Return: True s'il y a eu changement du cadre, i.e. besoin d'un reshape pour les enfants. */
protocol Reshapable {
    func reshape() -> Bool
}

/** Pour les noeuds "déplaçable".
* 1. On prend le noeud : "grab",
* 2. On le déplace : "drag",
* 3. On le relâche : "letGo".
* Retourne s'il y a une "action / event".
* Un noeud Draggable doit être dans une classe descendante de SearchableNode.
* On utilise les flags selectable et selectableRoot pour les trouver.
* (On peut être draggable mais pas actionable, e.g. le sliding menu.) */
protocol Draggable : SearchableNode {
    func grab(posInit: Vector2) -> Bool
    func drag(posNow: Vector2) -> Bool
    func letGo(speed: Vector2?) -> Bool
}
