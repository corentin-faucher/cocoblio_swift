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
/** Ici, delta est la demi-hauteur de la barre. */
class Bar : Surface {
	let framing: Framing
	let delta: Float
	
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
			case .inside:
				smallDeltaX = max(0, width/2 - 2 * delta)
			case .center:
				smallDeltaX = max(0, width/2 - delta)
			case .outside:
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

/** Ici, delta est la largeur des bords. (différent des barres) */
class Frame : Surface {
	let delta: Float
	let framing: Framing
	
	@discardableResult
	init(_ parent: Node, framing: Framing = .outside, delta: Float, texture: Texture,
		 width: Float?, height: Float?, lambda: Float = 0, flags: Int = 0)
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
        if let width = width, let height = height {
            update(width: width, height: height, fix: true)
        }
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
    // Init d'un cadre pour un littleBro
    @discardableResult
    convenience init(_ parent: Node, framing: Framing = .outside, delta: Float, texture: Texture,
                     lambda: Float = 0, flags: Int)
    {
        self.init(parent, framing: framing, delta: delta, texture: texture, width: nil, height: nil, lambda: lambda, flags: flags)
    }
    
    override func open() {
        guard containsAFlag(Flag1.frameOfParent), let parent = parent else { return }
        update(width: parent.width.realPos, height: parent.height.realPos, fix: true)
    }
    override func reshape() {
        guard containsAFlag(Flag1.frameOfParent), let parent = parent else { return }
        update(width: parent.width.realPos, height: parent.height.realPos, fix: false)
    }
	private func update(width: Float, height: Float, fix: Bool) {
		guard width >= 0, height >= 0 else { printerror("width < 0 or height < 0"); return }
		let smallDeltaX: Float
		let smallDeltaY: Float
		switch framing {
			case .inside:
				smallDeltaX = max(0, width/2 - delta)
				smallDeltaY = max(0, height/2 - delta)
			case .center:
				smallDeltaX = max(0, width/2 - delta/2)
				smallDeltaY = max(0, height/2 - delta/2)
			case .outside:
				smallDeltaX = width/2
				smallDeltaY = height/2
		}
        self.width.set(2 * (smallDeltaX + delta), fix)
        self.height.set(2 * (smallDeltaY + delta), fix)
        
		let xPos = 0.5 * smallDeltaX / (smallDeltaX + delta)
		let yPos = 0.5 * smallDeltaY / (smallDeltaY + delta)
		
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
            parent.setRelatively(fix: fix)
		}
	}
    
    @discardableResult
    func addLittleBroString(strTex: Texture, framedWidth: Float, framedHeight: Float) -> StringSurface
    {
        if framedHeight < 3 * delta || framedWidth < 3 * delta {
            printwarning("Frame too small.")
        }
        let str = StringSurface(self, strTex: strTex, 0, 0,
                                max(framedHeight - 2 * delta, delta), flags: Flag1.giveSizesToBigBroFrame,
                                ceiledWidth: max(framedWidth - 2 * delta, delta), asParent: false)
        str.x_margin = 0.7
        return str
    }
	func updateWithLittleBro(fix: Bool) {
		guard let bro = littleBro else { return }
		x.set(bro.x.realPos, fix)
		y.set(bro.y.realPos, fix)
		update(width: bro.deltaX * 2, height: bro.deltaY * 2, fix: fix)
	}
}

extension Node {
    /// Se base sur la taille du parent
    func fillWithFrameAndString(frameTex: Texture, deltaRatio: Float, strTex: Texture)
    {
        let frame = Frame(self, delta: deltaRatio * self.height.defPos, texture: frameTex, flags: Flag1.giveSizesToParent)
        frame.addLittleBroString(strTex: strTex, framedWidth: self.width.defPos, framedHeight: self.height.defPos)
    }
    /// N'ajuste pas la taille du parent
    func addFrameAndString(frameTex: Texture, deltaRatio: Float, strTex: Texture, height: Float)
    {
        let frame = Frame(self, delta: deltaRatio * self.height.defPos, texture: frameTex, flags: 0)
        frame.addLittleBroString(strTex: strTex, framedWidth: self.width.defPos, framedHeight: height)
    }
}

class FramedString : Node {
    var stringSurf: StringSurface {
        get {
            return lastChild as! StringSurface
        }
    }
    var frame: Frame {
        get {
            return firstChild as! Frame
        }
    }
    
    @discardableResult
    init(_ parent: Node?, strTex: Texture, frameTex: Texture,
         _ x: Float, _ y: Float, width: Float, height: Float,
         flags: Int = 0, deltaRatio: Float = 0.21, setWidth: Bool = false)
    {
        super.init(parent, x, y, width, height, flags: flags)
        
        let delta = min(deltaRatio * height, 0.45 * height)
        let frame = Frame(self, delta: delta, texture: frameTex, flags: Flag1.giveSizesToParent)
        let str = frame.addLittleBroString(strTex: strTex, framedWidth: width, framedHeight: height)
        if setWidth {
            str.setWidth(fix: true)
        }
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
}
