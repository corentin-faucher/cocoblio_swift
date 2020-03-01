//
//  Frame.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2020-01-28.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/** Noeud racine servant de cadre à une surface.
* (La surface étant placé en petit-frère.)
* Les enfants de Frame sont 9 surfaces créant le cadre. */
final class Frame : Node {
    private let delta: Float
    private let lambda: Float
    private var pngID: String
    private let isInside: Bool
    
    @discardableResult
    init(_ refNode: Node?, isInside: Bool = false,
         delta: Float = 0.1, lambda: Float = 0,
         framePngID: String = "frame_mocha", flags: Int = 0) {
        self.delta = delta
        self.lambda = lambda
        self.pngID = framePngID
        self.isInside = isInside
        super.init(refNode, 0, 0, delta, delta, lambda: lambda, flags: flags)
    }
    
    /** Constructeur de copie. */
    required internal init(refNode: Node?, toCloneNode: Node,
         asParent: Bool, asElderBigbro: Bool) {
        let toCloneFrame = toCloneNode as! Frame
        delta = toCloneFrame.delta
        lambda = toCloneFrame.lambda
        pngID = toCloneFrame.pngID
        isInside = toCloneFrame.isInside
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
    
    /** Init ou met à jour un noeud frame
     * (Ajoute les descendants si besoin) */
    func update(width: Float, height: Float, fix: Bool) {
        let refSurf = Surface(nil, pngID: pngID, 0, 0,
                              delta, lambda: lambda,
                              flags: Flag1.surfaceDontRespectRatio)
        
        let sq = Squirrel(at: self)
        let deltaX = isInside ? max(width/2 - delta/2, delta/2) : (width/2 + delta/2)
        let deltaY = isInside ? max(height/2 - delta/2, delta/2) : (height/2 + delta/2)
        let smallWidth = isInside ? max(width - delta, 0) : width
        let smallHeight = isInside ? max(height - delta, 0) : height
        
        // Mise à jour des dimensions.
        self.width.set(smallWidth + 2 * delta, true, true)
        self.height.set(smallHeight + 2 * delta, true, true)
        
        sq.goDownForced(refSurf) // tl
        (sq.pos as? Surface)?.updateTile(0, 0)
        sq.pos.x.set(-deltaX, fix, true)
        sq.pos.y.set(deltaY, fix, true)
        sq.goRightForced(refSurf) // t
        (sq.pos as? Surface)?.updateTile(1, 0)
        sq.pos.x.set(0, fix, true)
        sq.pos.y.set(deltaY, fix, true)
        sq.pos.width.set(smallWidth, fix, true)
        sq.goRightForced(refSurf) // tr
        (sq.pos as? Surface)?.updateTile(2, 0)
        sq.pos.x.set(deltaX, fix, true)
        sq.pos.y.set(deltaY, fix, true)
        sq.goRightForced(refSurf) // l
        (sq.pos as? Surface)?.updateTile(3, 0)
        sq.pos.x.set(-deltaX, fix, true)
        sq.pos.y.set(0, fix, true)
        sq.pos.height.set(smallHeight, fix, true)
        sq.goRightForced(refSurf) // c
        (sq.pos as? Surface)?.updateTile(4, 0)
        sq.pos.x.set(0, fix, true)
        sq.pos.y.set(0, fix, true)
        sq.pos.width.set(smallWidth, fix, true)
        sq.pos.height.set(smallHeight, fix, true)
        sq.goRightForced(refSurf) // r
        (sq.pos as? Surface)?.updateTile(5, 0)
        sq.pos.x.set(deltaX, fix, true)
        sq.pos.y.set(0, fix, true)
        sq.pos.height.set(smallHeight, fix, true)
        sq.goRightForced(refSurf) // bl
        (sq.pos as? Surface)?.updateTile(6, 0)
        sq.pos.x.set(-deltaX, fix, true)
        sq.pos.y.set(-deltaY, fix, true)
        sq.goRightForced(refSurf) // b
        (sq.pos as? Surface)?.updateTile(7, 0)
        sq.pos.x.set(0, fix, true)
        sq.pos.y.set(-deltaY, fix, true)
        sq.pos.width.set(smallWidth, fix, true)
        sq.goRightForced(refSurf) // br
        (sq.pos as? Surface)?.updateTile(8, 0)
        sq.pos.x.set(deltaX, fix, true)
        sq.pos.y.set(-deltaY, fix, true)
    }
    
    func updatePng(newPngId: String) {
        if newPngId == pngID {
            return
        }
        pngID = newPngId
        guard let theFirstChild = firstChild else {printerror("Frame pas init."); return}
        let sq = Squirrel(at: theFirstChild)
        repeat {
            (sq.pos as? Surface)?.updateForTex(pngID: pngID)
        } while sq.goRight()
    }
}
