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
class Bar : Surface {
	private var framing: Framing
	private let delta: Float
	
	@discardableResult
	init(parent: Node, framing: Framing, delta: Float, width: Float, texture: Texture, lambda: Float = 0)
	{	
		self.delta = delta
		self.framing = framing
        super.init(parent, tex: texture, 0, 0, delta * 2, lambda: lambda, flags: Flag1.surfaceDontRespectRatio,
                   mesh: Mesh(vertices:
                                [((-0.5000, 0.5, 0), (0.000,0), (0,0,1)),
                                 ((-0.5000,-0.5, 0), (0.000,1), (0,0,1)),
                                 ((-0.1667, 0.5, 0), (0.333,0), (0,0,1)),
                                 ((-0.1667,-0.5, 0), (0.333,1), (0,0,1)),
                                 (( 0.1667, 0.5, 0), (0.667,0), (0,0,1)),
                                 (( 0.1667,-0.5, 0), (0.667,1), (0,0,1)),
                                 (( 0.5000, 0.5, 0), (1.000,0), (0,0,1)),
                                 (( 0.5000,-0.5, 0), (1.000,1), (0,0,1))],
                                        indices: [],
                                        primitive: .triangleStrip))
        self.width.set(delta * 4)
		update(width: width, fix: true)
	}
	required init(other: Node) {
		let otherBar = other as! Bar
		delta = otherBar.delta
		framing = otherBar.framing
		super.init(other: other)
        mesh = Mesh(other: otherBar.mesh)
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
		
//		mesh.updateVerticesBuffer()
	}
	
	func updateWithLittleBro(fix: Bool) {
		guard let bro = littleBro else { return }
		x.set(bro.x.realPos, fix)
		y.set(bro.y.realPos, fix)
		update(width: bro.deltaX * 2, fix: fix)
	}
}

class Frame : Surface {
	private let delta: Float
	private var framing: Framing
	
	@discardableResult
	init(_ parent: Node, framing: Framing = .inside, delta: Float,
         lambda: Float = 0, texture: Texture,
		 width: Float = 0, height: Float = 0, flags: Int = 0)
	{
		self.delta = delta
		self.framing = framing
        super.init(parent, tex: texture, 0, 0, delta * 2,
                   lambda: lambda, flags: flags | Flag1.surfaceDontRespectRatio,
                   mesh: Mesh(vertices:
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
                                        primitive: .triangle))
		update(width: width, height: height, fix: true)
	}
	required init(other: Node)
	{
		let otherFrame = other as! Frame
		delta = otherFrame.delta
		framing = otherFrame.framing
		super.init(other: other)
        // Chaque frame a sa propre mesh...
        mesh = Mesh(other: otherFrame.mesh)
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
		
//		mesh.updateVerticesBuffer()
        
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
