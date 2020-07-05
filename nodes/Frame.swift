//
//  Frame.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2020-01-28.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

enum Framing {
	case outside
	case center
	case inside
}

/** Crée une barre. framing est pour l'emplacement des bords. width est la largeur du contenu (sans les bords). delta est la demi-épaisseur. */
class Bar : Node, Surface {
	let tex: Texture
	let mesh: Mesh
	var trShow = SmTrans()
	var framing: Framing
	/// Demi-hauteur de la barre.
	let delta: Float
	
	@discardableResult
	init(parent: Node, framing: Framing, delta: Float, width: Float, texture: Texture, lambda: Float = 0)
	{	
		self.delta = delta
		self.tex = texture
		self.framing = framing
		
		mesh = Mesh(vertices:
			[((-0.5000, 0.5, 0), (0.000,0), (0,0,1)),
			 ((-0.5000,-0.5, 0), (0.000,1), (0,0,1)),
			 ((-0.1667, 0.5, 0), (0.333,0), (0,0,1)),
			 ((-0.1667,-0.5, 0), (0.333,1), (0,0,1)),
			 (( 0.1667, 0.5, 0), (0.667,0), (0,0,1)),
			 (( 0.1667,-0.5, 0), (0.667,1), (0,0,1)),
			 (( 0.5000, 0.5, 0), (1.000,0), (0,0,1)),
			 (( 0.5000,-0.5, 0), (1.000,1), (0,0,1))],
					indices: [],
					primitive: .triangleStrip)
		super.init(parent, 0, 0, delta * 4, delta * 2,
				   lambda: lambda, flags: Flag1.surfaceDontRespectRatio)
		update(width: width, fix: true)
	}
	required init(other: Node) {
		let otherBar = other as! Bar
		delta = otherBar.delta
		mesh = Mesh(other: otherBar.mesh)
		tex = otherBar.tex
		framing = otherBar.framing
		super.init(other: other)
	}
	
	func update(width: Float, fix: Bool) {
		guard width >= 0 else {printerror("deltaX < 0"); return}
		let smallDeltaX: Float
		switch framing {
			case .outside:
				smallDeltaX = max(0, width/2 - 2 * delta)
			case .center:
				smallDeltaX = max(0, width/2 - delta)
			case .inside:
				smallDeltaX = width/2
		}
		
		let xPos = 0.5 * smallDeltaX / (smallDeltaX + 2 * delta)
		self.width.set(2 * (smallDeltaX + 2 * delta), fix)
		
		mesh.vertices[2].position.0 = -xPos
		mesh.vertices[3].position.0 = -xPos
		mesh.vertices[4].position.0 =  xPos
		mesh.vertices[5].position.0 =  xPos
		
		mesh.updateVerticesBuffer()
	}
	
	func updateWithLittleBro(fix: Bool) {
		guard let bro = littleBro else { return }
		x.set(bro.x.realPos, fix)
		y.set(bro.y.realPos, fix)
		update(width: bro.deltaX * 2, fix: fix)
	}
}

class Frame : Node, Surface {
	var tex: Texture
	let mesh: Mesh
	var trShow = SmTrans()
	let delta: Float
	var framing: Framing
	
	@discardableResult
	init(_ parent: Node, framing: Framing = .inside, delta: Float, lambda: Float = 0, texture: Texture,
		 width: Float = 0, height: Float = 0, flags: Int = 0)
	{
		self.tex = texture
		self.delta = delta
		self.framing = framing
		
		mesh = Mesh(vertices:
			[((-0.5000, 0.5000, 0), (0.000,0.000), (0,0,1)),
			 ((-0.5000, 0.1667, 0), (0.000,0.333), (0,0,1)),
			 ((-0.5000,-0.1667, 0), (0.000,0.667), (0,0,1)),
			 ((-0.5000,-0.5000, 0), (0.000,1.000), (0,0,1)),
			 ((-0.1667, 0.5000, 0), (0.333,0.000), (0,0,1)),
			 ((-0.1667, 0.1667, 0), (0.333,0.333), (0,0,1)),
			 ((-0.1667,-0.1667, 0), (0.333,0.667), (0,0,1)),
			 ((-0.1667,-0.5000, 0), (0.333,1.000), (0,0,1)),
			 (( 0.1667, 0.5000, 0), (0.667,0.000), (0,0,1)),
			 (( 0.1667, 0.1667, 0), (0.667,0.333), (0,0,1)),
			 (( 0.1667,-0.1667, 0), (0.667,0.667), (0,0,1)),
			 (( 0.1667,-0.5000, 0), (0.667,1.000), (0,0,1)),
			 (( 0.5000, 0.5000, 0), (1.000,0.000), (0,0,1)),
			 (( 0.5000, 0.1667, 0), (1.000,0.333), (0,0,1)),
			 (( 0.5000,-0.1667, 0), (1.000,0.667), (0,0,1)),
			 (( 0.5000,-0.5000, 0), (1.000,1.000), (0,0,1))],
					indices: [
						0, 1, 4,  1, 5, 4,
						1, 2, 5,  2, 6, 5,
						2, 3, 6,  3, 7, 6,
						4, 5, 8,  5, 9, 8,
						5, 6, 9,  6, 10, 9,
						6, 7, 10, 7, 11, 10,
						8, 9, 12, 9, 13, 12,
						9, 10, 13, 10, 14, 13,
						10, 11, 14, 11, 15, 14 ],
					primitive: .triangle)
		super.init(parent, 0, 0, delta * 2, delta * 2, lambda: lambda, flags: flags | Flag1.surfaceDontRespectRatio)
		update(width: width, height: height, fix: true)
	}
	required init(other: Node)
	{
		let otherFrame = other as! Frame
		tex = otherFrame.tex
		delta = otherFrame.delta
		framing = otherFrame.framing
		mesh = Mesh(other: otherFrame.mesh)
		super.init(other: other)
	}
	func update(width: Float, height: Float, fix: Bool) {
		guard width >= 0, height >= 0 else { printerror("width < 0 or height < 0"); return }
		let smallDeltaX: Float
		let smallDeltaY: Float
		switch framing {
			case .outside:
				smallDeltaX = max(0, width/2 - 2 * delta)
				smallDeltaY = max(0, height/2 - 2 * delta)
			case .center:
				smallDeltaX = max(0, width/2 - delta)
				smallDeltaY = max(0, height/2 - delta)
			case .inside:
				smallDeltaX = width/2
				smallDeltaY = height/2
		}
		
		let xPos = 0.5 * smallDeltaX / (smallDeltaX + 2 * delta)
		let yPos = 0.5 * smallDeltaY / (smallDeltaY + 2 * delta)
		self.width.set(2 * (smallDeltaX + 2 * delta), fix)
		self.height.set(2 * (smallDeltaY + 2 * delta), fix)
		
		mesh.vertices[4].position.0 = -xPos
		mesh.vertices[5].position.0 = -xPos
		mesh.vertices[6].position.0 = -xPos
		mesh.vertices[7].position.0 = -xPos
		mesh.vertices[8].position.0 =  xPos
		mesh.vertices[9].position.0 =  xPos
		mesh.vertices[10].position.0 = xPos
		mesh.vertices[11].position.0 = xPos
		
		mesh.vertices[1].position.1 =   yPos
		mesh.vertices[5].position.1 =   yPos
		mesh.vertices[9].position.1 =   yPos
		mesh.vertices[13].position.1 =  yPos
		mesh.vertices[2].position.1 =  -yPos
		mesh.vertices[6].position.1 =  -yPos
		mesh.vertices[10].position.1 = -yPos
		mesh.vertices[14].position.1 = -yPos
		
		mesh.updateVerticesBuffer()
		if let parent = parent, containsAFlag(Flag1.giveSizesToParent) {
			parent.width.set(self.width.realPos)
			parent.height.set(self.height.realPos)
		}
	}
	func updateWithLittleBro(fix: Bool) {
		guard let bro = littleBro else { return }
		x.set(bro.x.realPos, fix)
		y.set(bro.y.realPos, fix)
		update(width: bro.deltaX * 2, height: bro.deltaY * 2, fix: fix)
	}
}

/*
final class Frame_ : Node {
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
        let otherFrame = other as! Frame_
        delta = otherFrame.delta
        lambda = otherFrame.lambda
        texture = otherFrame.texture
        isInside = otherFrame.isInside
        super.init(other: other)
    }
	
	@discardableResult
	func preSetWidthAndHeightFrom(width: Float, height: Float) -> (smWidth: Float, smHeight: Float)
	{
		let smallWidth = isInside ? max(width - delta, 0) : width
		let smallHeight = isInside ? max(height - delta, 0) : height
		self.width.set(smallWidth + 2 * delta, true, true)
		self.height.set(smallHeight + 2 * delta, true, true)
		if let theParent = parent, containsAFlag(Flag1.giveSizesToParent) {
			theParent.width.set(self.width.realPos)
			theParent.height.set(self.height.realPos)
		}
		return (smallWidth, smallHeight)
	}
	
    /** Init ou met à jour un noeud frame
     * (Ajoute les descendants si besoin) */
    func update(width: Float, height: Float, fix: Bool) {
		let showFlag = containsAFlag(Flag1.show) ? Flag1.show : 0
        let refSurf = TiledSurface(nil, pngTex: texture, 0, 0, delta, lambda: lambda,
								   flags: Flag1.surfaceDontRespectRatio | showFlag)
        
        let sq = Squirrel(at: self)
        let deltaX = isInside ? max(width/2 - delta/2, delta/2) : (width/2 + delta/2)
        let deltaY = isInside ? max(height/2 - delta/2, delta/2) : (height/2 + delta/2)
        
		let (smallWidth, smallHeight) = preSetWidthAndHeightFrom(width: width, height: height)
        
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
*/

