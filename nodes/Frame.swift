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
    private var texture: Texture
    private let isInside: Bool
    
    @discardableResult
    init(_ refNode: Node?, isInside: Bool = false,
         delta: Float = 0.1, lambda: Float = 0,
         texture: Texture, flags: Int = 0) {
        self.delta = delta
        self.lambda = lambda
        self.texture = texture
        self.isInside = isInside
        super.init(refNode, 0, 0, delta, delta, lambda: lambda, flags: flags)
    }
    required init(other: Node) {
        let otherFrame = other as! Frame
        delta = otherFrame.delta
        lambda = otherFrame.lambda
        texture = otherFrame.texture
        isInside = otherFrame.isInside
        super.init(other: other)
    }
    /** Init ou met à jour un noeud frame
     * (Ajoute les descendants si besoin) */
    func update(width: Float, height: Float, fix: Bool) {
        let refSurf = TiledSurface(nil, pngTex: texture, 0, 0, delta, lambda: lambda,
								   flags: Flag1.surfaceDontRespectRatio)
        
        let sq = Squirrel(at: self)
        let deltaX = isInside ? max(width/2 - delta/2, delta/2) : (width/2 + delta/2)
        let deltaY = isInside ? max(height/2 - delta/2, delta/2) : (height/2 + delta/2)
        let smallWidth = isInside ? max(width - delta, 0) : width
        let smallHeight = isInside ? max(height - delta, 0) : height
        
        // Mise à jour des dimensions.
        self.width.set(smallWidth + 2 * delta, true, true)
        self.height.set(smallHeight + 2 * delta, true, true)
        if let theParent = parent, containsAFlag(Flag1.giveSizesToParent) {
            theParent.width.set(self.width.realPos)
            theParent.height.set(self.height.realPos)
        }
        
        sq.goDownForced(refSurf) // tl
        (sq.pos as? TiledSurface)?.updateTile(0, 0)
        sq.pos.x.set(-deltaX, fix, true)
        sq.pos.y.set(deltaY, fix, true)
        sq.goRightForced(refSurf) // t
        (sq.pos as? TiledSurface)?.updateTile(1, 0)
        sq.pos.x.set(0, fix, true)
        sq.pos.y.set(deltaY, fix, true)
        sq.pos.width.set(smallWidth, fix, true)
        sq.goRightForced(refSurf) // tr
        (sq.pos as? TiledSurface)?.updateTile(2, 0)
        sq.pos.x.set(deltaX, fix, true)
        sq.pos.y.set(deltaY, fix, true)
        sq.goRightForced(refSurf) // l
        (sq.pos as? TiledSurface)?.updateTile(3, 0)
        sq.pos.x.set(-deltaX, fix, true)
        sq.pos.y.set(0, fix, true)
        sq.pos.height.set(smallHeight, fix, true)
        sq.goRightForced(refSurf) // c
        (sq.pos as? TiledSurface)?.updateTile(4, 0)
        sq.pos.x.set(0, fix, true)
        sq.pos.y.set(0, fix, true)
        sq.pos.width.set(smallWidth, fix, true)
        sq.pos.height.set(smallHeight, fix, true)
        sq.goRightForced(refSurf) // r
        (sq.pos as? TiledSurface)?.updateTile(5, 0)
        sq.pos.x.set(deltaX, fix, true)
        sq.pos.y.set(0, fix, true)
        sq.pos.height.set(smallHeight, fix, true)
        sq.goRightForced(refSurf) // bl
        (sq.pos as? TiledSurface)?.updateTile(6, 0)
        sq.pos.x.set(-deltaX, fix, true)
        sq.pos.y.set(-deltaY, fix, true)
        sq.goRightForced(refSurf) // b
        (sq.pos as? TiledSurface)?.updateTile(7, 0)
        sq.pos.x.set(0, fix, true)
        sq.pos.y.set(-deltaY, fix, true)
        sq.pos.width.set(smallWidth, fix, true)
        sq.goRightForced(refSurf) // br
        (sq.pos as? TiledSurface)?.updateTile(8, 0)
        sq.pos.x.set(deltaX, fix, true)
        sq.pos.y.set(-deltaY, fix, true)
    }
    
	func updateTexture(_ newTexture: Texture) {
        if newTexture === texture {
            return
        }
        texture = newTexture
        guard let theFirstChild = firstChild else {printerror("Frame pas init."); return}
        let sq = Squirrel(at: theFirstChild)
        repeat {
			(sq.pos as? TiledSurface)?.updateTexture(newTexture)
        } while sq.goRight()
    }
}
