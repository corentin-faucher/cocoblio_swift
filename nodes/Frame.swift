//
//  Frame.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2020-01-28.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

final class Frame : Node {
    let delta: Float
    let lambda: Float
    let tex: Texture
    
    @discardableResult
    init(_ refNode: Node?, delta: Float, lambda: Float,
         texEnum: TexEnum) {
        self.delta = delta
        self.lambda = lambda
        self.tex = TexEnum.texFor(texEnum)
        super.init(refNode, 0, 0, delta, delta)
    }
    
    /** Constructeur de copie. */
    required internal init(refNode: Node?, toCloneNode: Node,
         asParent: Bool, asElderBigbro: Bool) {
        delta = (toCloneNode as! Frame).delta
        lambda = (toCloneNode as! Frame).lambda
        tex = (toCloneNode as! Frame).tex
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
    
    /** Init ou met à jour un noeud frame
     * (Ajoute les descendants si besoin) */
    func update(width: Float, height: Float,
                fix: Bool, inside: Bool = false) {
        let refSurf = Surface(nil, tex, 0, 0, delta, lambda: lambda)
        
        let sq = Squirrel(at: self)
        let deltaX = inside ? max(width/2 - delta/2, delta/2) : (width/2 + delta/2)
        let deltaY = inside ? max(height/2 - delta/2, delta/2) : (height/2 + delta/2)
        let smallWidth = inside ? max(width - delta, 0) : width
        let smallHeight = inside ? max(height - delta, 0) : height
        
        // Mise à jour des dimensions.
        self.width.setPos(smallWidth + 2 * delta, true, true)
        self.height.setPos(smallHeight + 2 * delta, true, true)
        
        sq.goDownForced(refSurf) // tl
        (sq.pos as? Surface)?.updateTile(0, 0)
        sq.pos.x.setPos(-deltaX, fix, true)
        sq.pos.y.setPos(deltaY, fix, true)
        sq.goRightForced(refSurf) // t
        (sq.pos as? Surface)?.updateTile(1, 0)
        sq.pos.x.setPos(0, fix, true)
        sq.pos.y.setPos(deltaY, fix, true)
        sq.pos.width.setPos(smallWidth, fix, true)
        sq.goRightForced(refSurf) // tr
        (sq.pos as? Surface)?.updateTile(2, 0)
        sq.pos.x.setPos(deltaX, fix, true)
        sq.pos.y.setPos(deltaY, fix, true)
        sq.goRightForced(refSurf) // l
        (sq.pos as? Surface)?.updateTile(3, 0)
        sq.pos.x.setPos(-deltaX, fix, true)
        sq.pos.y.setPos(0, fix, true)
        sq.pos.height.setPos(smallHeight, fix, true)
        sq.goRightForced(refSurf) // c
        (sq.pos as? Surface)?.updateTile(4, 0)
        sq.pos.x.setPos(0, fix, true)
        sq.pos.y.setPos(0, fix, true)
        sq.pos.width.setPos(smallWidth, fix, true)
        sq.pos.height.setPos(smallHeight, fix, true)
        sq.goRightForced(refSurf) // r
        (sq.pos as? Surface)?.updateTile(5, 0)
        sq.pos.x.setPos(deltaX, fix, true)
        sq.pos.y.setPos(0, fix, true)
        sq.pos.height.setPos(smallHeight, fix, true)
        sq.goRightForced(refSurf) // bl
        (sq.pos as? Surface)?.updateTile(6, 0)
        sq.pos.x.setPos(-deltaX, fix, true)
        sq.pos.y.setPos(-deltaY, fix, true)
        sq.goRightForced(refSurf) // b
        (sq.pos as? Surface)?.updateTile(7, 0)
        sq.pos.x.setPos(0, fix, true)
        sq.pos.y.setPos(-deltaY, fix, true)
        sq.pos.width.setPos(smallWidth, fix, true)
        sq.goRightForced(refSurf) // br
        (sq.pos as? Surface)?.updateTile(8, 0)
        sq.pos.x.setPos(deltaX, fix, true)
        sq.pos.y.setPos(-deltaY, fix, true)
    }
}
