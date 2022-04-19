import Foundation

class Surface: Node {
    var tex: Texture
    var mesh: Mesh
    var trShow: SmTrans
    var trExtra: SmTrans
    var x_margin: Float = 0
    
    @discardableResult
    init(_ refNode: Node?, tex: Texture,
         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, mesh: Mesh = .sprite, asParent: Bool = true, asElderBigbro: Bool = false) {
        self.tex = tex
        self.mesh = mesh
        self.trShow = SmTrans()
        self.trExtra = SmTrans()
        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags, //|Flag1.isSurface,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
    @discardableResult
    convenience init(_ refNode: Node?, color: Vector4,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, mesh: Mesh = .sprite, asParent: Bool = true, asElderBigbro: Bool = false) {
        self.init(refNode, tex: Texture.justColor, x, y, height, lambda: lambda,
                  flags: flags | Flag1.surfaceDontRespectRatio, mesh: mesh, asParent: asParent, asElderBigbro: asElderBigbro)
        self.width.set(width)
        piu.color = color
    }
    
    required init(other: Node) {
        let otherSurf = other as! Surface
        tex = otherSurf.tex
        mesh = otherSurf.mesh
        trShow = otherSurf.trShow
        trExtra = otherSurf.trExtra
        super.init(other: other)
    }
    
    override func isDisplayActive() -> Bool {
        return trShow.isActive
    }
    
    func setWidth(fix: Bool) {
        guard !containsAFlag(Flag1.surfaceDontRespectRatio) else {return}
        
        // 1. Largeur en fonction du ratio, marge en x et plafond.
        let extra_x = deltaY * x_margin
        if containsAFlag(Flag1.stringSurfaceWithCeiledWidth), width.defPos > 2 * extra_x {
            width.set(min((width.defPos - extra_x) / tex.scaleX, height.realPos * tex.ratio), fix, false)
        } else {
            width.set(height.realPos * tex.ratio, fix, true)
        }
        // 2. Ajustement du spacing en x
        scaleX.set(tex.scaleX + extra_x / width.realPos)
        // 3. Ajuster le frame (si besoin)
        if containsAFlag(Flag1.giveSizesToBigBroFrame), let bigBroFrame = bigBro as? Frame {
            bigBroFrame.updateWithLittleBro(fix: fix)
        }
        // 4. Donner les dimensions au parent (si besoin)
        if containsAFlag(Flag1.giveSizesToParent), let theParent = parent  {
            theParent.width.set(deltaX * 2)
            theParent.height.set(deltaY * 2)
            theParent.setRelatively(fix: fix)
        }
    }
}


class StringSurface: Surface //, Openable
{
    /** On prend pour aquis que la texture reçu est déjà une texture avec une string. */
	@discardableResult
	init(_ refNode: Node?, strTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, ceiledWidth: Float? = nil,
		 asParent: Bool = true, asElderBigbro: Bool = false)
    {
        guard strTex.type != .png else {
			printerror("Pas une texture de string")
            super.init(refNode, tex: Texture.defaultString, x, y, height, lambda: lambda, flags: flags,
                       mesh: .sprite, asParent: asParent, asElderBigbro: asElderBigbro)
            width.set(ceiledWidth ?? height)
			return
		}
        super.init(refNode, tex: strTex, x, y, height, lambda: lambda, flags: flags,
                   mesh: .sprite, asParent: asParent, asElderBigbro: asElderBigbro)
        width.set(ceiledWidth ?? height)
		if ceiledWidth != nil {
			addFlags(Flag1.stringSurfaceWithCeiledWidth)
		}
        if strTex.name.first?.isEmoji ?? false {
            piu.color = Color.white
        } else {
            piu.color = Color.black // (Text noir par défaut.)
        }
	}
	@discardableResult
    convenience init(_ refNode: Node?, cstString: String, fontname: String? = nil,
					 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
					 flags: Int = 0, ceiledWidth: Float? = nil,
					 asParent: Bool = true, asElderBigbro: Bool = false)
    {
		self.init(refNode, strTex: Texture.getConstantString(cstString, fontname: fontname),
				  x, y, height, lambda: lambda, flags: flags, //|Flag1.isSurface,
                  ceiledWidth: ceiledWidth,
				  asParent: asParent, asElderBigbro: asElderBigbro)
	}
	required init(other: Node) {
		super.init(other: other)
	}
    override func open() {
		setWidth(fix: true)
        super.open()
	}
	/** Change la texture du noeud (devrait être une string). */
	func updateStringTexture(_ newTexture: Texture) {
        guard newTexture.type != .png else {
			printerror("Not a string texture")
			return
		}
		tex = newTexture
        if tex.name.first?.isEmoji ?? false {
            piu.color = Color.white
        } else {
            piu.color = Color.black
        }
	}
	/** "Convenience function": Ne change pas la texture. Ne fait que mettre à jour la string de la texture. */
    func updateAsMutableString(_ newString: String, fontname: String? = nil) {
        guard tex.type == .mutableString else {
			printerror("Not a mutable string texture.")
			return
		}
		tex.updateAsMutableString(newString)
	}
	/** "Convenience function": Remplace la texture actuel pour une texture de string constant (non mutable). */
    func updateTextureToConstantString(_ newString: String, fontname: String? = nil) {
		tex = Texture.getConstantString(newString, fontname: fontname)
        if tex.name.first?.isEmoji ?? false {
            piu.color = Color.white
        } else {
            piu.color = Color.black
        }
	}
    
    override func setWidth(fix: Bool) {
        // 1. Vérifier l'espacement en y.
        scaleY.set(tex.scaleY) // y en premier... (scalex dépend de deltaY...)
        // 2. Height s'ajuste au scaling pour garder deltay constant... defPos == 2 * deltaY
        height.set(height.defPos / scaleY.realPos, fix, false)
        
        // 3. Ajuster la largeur comme pour les autres surface...
        super.setWidth(fix: fix)
    }
}

/** Surface avec tiles (e.g. ensemble de 4x4 icones dans un png.) */
class TiledSurface: Surface {
	@discardableResult
	init(_ refNode: Node?, pngTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0, i: Int = 0, flags: Int = 0,
         mesh: Mesh = .sprite, asParent: Bool = true, asElderBigbro: Bool = false
	) {
        guard pngTex.type == .png else {
			printerror("String texture (need standand texture).")
            super.init(refNode, tex: Texture.defaultPng, x, y, height, lambda: lambda, flags: flags,
                       mesh: mesh, asParent: asParent, asElderBigbro: asElderBigbro)
			return
		}
        super.init(refNode, tex: pngTex, x, y, height, lambda: lambda, flags: flags,
                   mesh: mesh, asParent: asParent, asElderBigbro: asElderBigbro)
		setWidth(fix: true)
		updateTile(i, 0)
	}
	required init(other: Node) {
		super.init(other: other)
	}
	/** Si i > m -> va sur les lignes suivantes. */
	func updateTile(_ i: Int, _ j: Int) {
		piu.tile = (Float(i % tex.m),
					Float((j + i / tex.m) % tex.n))
	}
	/** Ne change que l'index "i" de la tile (ligne) */
	func updateTileI(_ index: Int) {
		piu.tile.i = Float(index % tex.m)
	}
	/** Ne change que l'index "j" de la tile (colonne) */
	func updateTileJ(_ index: Int) {
		piu.tile.j = Float(index % tex.n)
	}
	/** Ne change que la texture (pas de setWidth). */
	func updateTexture(_ newTexture: Texture) {
        guard newTexture.type == .png else {
			printerror("Not a png texture.")
			return
		}
		tex = newTexture
	}
}

final class PopDisk : TiledSurface {
    private var timer1, timer2: Timer!
    private var chrono = Chrono()
    private let deltaT: Float
    
    @discardableResult
    init?(_ refNode: Node, pngTex: Texture, deltaT: Float, _ x: Float, _ y: Float, _ height: Float,
          lambda: Float, i: Int, flags: Int = 0
    ) {
        self.deltaT = deltaT
        super.init(refNode, pngTex: pngTex, x, y, height,
                   lambda: lambda, i: i, flags: flags, mesh: FanMesh())
        (mesh as! FanMesh).update(with: 0)
        chrono.start()
        self.y.fadeInFromDef(delta: height)
        width.fadeIn(delta: -height * 0.3)
        self.height.fadeIn(delta: -height * 0.3)
        openAndShowBranch()
        
        timer1 = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] (_) in
            if let self = self {
                (self.mesh as! FanMesh).update(with: min(self.chrono.elapsedSec / deltaT, 1))
            }
        }
        timer2 = Timer.scheduledTimer(withTimeInterval: Double(deltaT), repeats: false) { [weak self] (_) in
            self?.closeBranch()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] (_) in
                self?.disconnect()
            }
        }
        
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    func discard() {
        guard self.chrono.elapsedSec > 0.3*deltaT else {
            Timer.scheduledTimer(withTimeInterval: 0.32*Double(deltaT) - Double(self.chrono.elapsedSec), repeats: false) { [weak self] (_) in
                self?.discard()
            }
            return
        }
        closeBranch()
        timer1.invalidate()
        timer2.invalidate()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] (_) in
            self?.disconnect()
        }
    }
}

class LanguageSurface: Surface
{
	@discardableResult
	init(_ refNode: Node?, pngTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
		 flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false
	) {
        guard pngTex.type == .png else {
			printerror("Not a png.")
            super.init(refNode, tex: Texture.defaultPng, x, y, height, lambda: lambda, flags: flags,
                       mesh: .sprite, asParent: asParent, asElderBigbro: asElderBigbro)
			return
		}
        super.init(refNode, tex: pngTex, x, y, height, lambda: lambda, flags: flags,
                   mesh: .sprite, asParent: asParent, asElderBigbro: asElderBigbro)
		setWidth(fix: true)
	}
	required init(other: Node) {
		super.init(other: other)
	}
    override func open() {
        super.open()
		let i = Language.currentTileId
		piu.tile = (Float(i % tex.m),
					Float((i / tex.m) % tex.n))
	}
	func updateTexture(_ newTexture: Texture) {
        guard newTexture.type == .png else {
			printerror("Not a png.")
			return
		}
		tex = newTexture
	}
}

class TestFrame : Surface
{
	@discardableResult
	init(_ refNode: Node) {
        super.init(refNode, tex: Texture.testFrame, 0, 0, refNode.height.realPos, lambda: 10,
                   flags: Flag1.surfaceDontRespectRatio | Flag1.notToAlign, //|Flag1.isSurface,
                   mesh: .sprite)
        width.set(refNode.width.realPos)
	}
	required init(other: Node) {
		super.init(other: other)
	}
	
    override func open() {
		guard let theParent = parent else { printerror("TestFrame sans parent."); return}
		height.pos = theParent.height.realPos
		width.pos = theParent.width.realPos
        super.open()
	}
	
    override func reshape() {
		open()
	}
}
