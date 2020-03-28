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

/** Le noeud racine contrôle la caméra.
 	 En effet sa matrice "model" est une matrice "lookAt"
	 étant la première transformation pour tout les objets.
 	 Les positions (x,y,z) sont la position de la caméra.
 	 Par défaut on regarde vers l'origine (0,0,0). */
class RootNode : Node, Reshapable {
    private let up: Vector3 = [0, 1, 0]
    var yLookAt = SmoothPos(0, 5)
    let renderer: Renderer
    
    /// Déplacement relatif de la vue dans son cadre (voir fullHeight vs usableHeight).
    /// Les valeurs acceptable sont entre [-1, 1]. -1: collé en bas, +1: collé en haut.
    let yRelativeDisplacement = SmoothPos(0, 8)
    
    init(refNode: Node? = nil, renderer: Renderer) {
        self.renderer = renderer
        super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: Flag1.exposed|Flag1.show|Flag1.branchToDisplay|Flag1.selectableRoot)
        z.set(4)
    }
    required init(other: Node) {
        renderer = (other as! RootNode).renderer
        super.init(other: other)
    }
    func setModelAsCamera() {
        let yShift = Float(renderer.fullFrame.height - renderer.usableFrame.height) * yRelativeDisplacement.pos / 2
        piu.model.setToLookAt(eye: [x.pos, y.pos + yShift, z.pos], center: [0, yLookAt.pos + yShift, 0], up: up)
    }
    func setProjectionMatrix(_ projection: inout float4x4) {
        projection.setToPerspective(nearZ: 0.1, farZ: 50, middleZ: z.pos,
                                    deltaX: Float(renderer.fullFrame.width),
                                    deltaY: Float(renderer.fullFrame.height))
    }
    func reshape() -> Bool {
        width.set(Float(renderer.usableFrame.width))
        height.set(Float(renderer.usableFrame.height))
        return true
    }
}

