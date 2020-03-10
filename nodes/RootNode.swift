//
//  Root.swift
//  MasaKiokuGameOSX
//
//  Created by Corentin Faucher on 2020-02-07.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation
import simd
import CoreGraphics

/*-- Le noeud racine contrôle la caméra.
 	 En effet sa matrice "model" est une matrice "lookAt"
	 étant la première transformation pour tout les objets.
 	 Les positions (x,y,z) sont la position de la caméra.
 	 Par défaut on regarde vers l'origine (0,0,0).
 --*/
class RootNode : Node, Reshapable {
    private let up: Vector3 = [0, 1, 0]
    
    // * width et height ordinaire sont les "usableWidth/usableHeight" (sans les bords, les dimensions "utiles").
    // * fullWidth et fullHeight sont les "vrais" dimensions de la vue (y compris les bords
    // où il ne devrait pas y avoir d'objet importants).
    private(set) var fullWidth: Float = 2
    private(set) var fullHeight: Float = 2
    
    /// Déplacement relatif de la vue dans son cadre (voir fullHeight vs usableHeight).
    /// Les valeurs acceptable sont entre [-1, 1]. -1: collé en bas, +1: collé en haut.
    let yRelativeDisplacement = SmoothPos(0, 8)
    
    init(refNode: Node? = nil) {
        super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: Flag1.exposed|Flag1.show|Flag1.branchToDisplay|Flag1.selectableRoot)
        z.set(4)
    }
    required init(other: Node) {
        super.init(other: other)
    }
    func setModelAsCamera() {
        let yShift = (fullHeight - height.realPos) * yRelativeDisplacement.pos / 2
        piu.model.setToLookAt(eye: [x.pos, y.pos + yShift, z.pos], center: [0, yShift, 0], up: up)
    }
    func setProjectionMatrix(_ projection: inout float4x4) {
        projection.setToPerspective(nearZ: 0.1, farZ: 50, middleZ: z.pos,
        	deltaX: fullWidth, deltaY: fullHeight)
    }
    
    func updateUsableDims(size: CGSize) {
        let ratio = Float(size.width / size.height)
        if ratio > 1 { // Landscape
            width.set(min(2*ratio, 2*RootNode.ratioMax))
            height.set(2)
        }
        else {
            width.set(2)
            height.set(min(2/ratio, 2/RootNode.ratioMin))
        }
    }
    func updateFullDims(size: CGSize) {
        let ratio = Float(size.width / size.height)
        if ratio > 1 { // Landscape
            fullWidth = 2 * ratio / RootNode.defaultBordRatio
            fullHeight = 2 / RootNode.defaultBordRatio
        }
        else {
            fullWidth = 2 / RootNode.defaultBordRatio
            fullHeight = 2 / (ratio * RootNode.defaultBordRatio)
        }
    }
    func reshape() -> Bool {
        return true
    }
    
    static private let defaultBordRatio: Float = 0.95
    static private let ratioMin: Float = 0.54
    static private let ratioMax: Float = 1.85
}

