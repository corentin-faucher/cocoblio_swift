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
    /** Une surface "couleur" reçoit width et height.
     * Elle n'a pas de ratio fixé automatiquement avec le png et le tiling.
     * (Flag1.surfaceDontRespectRatio ajouté par défaut.) */
    @discardableResult
    convenience init(_ refNode: Node?, color: Vector4,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, mesh: Mesh = .sprite, asParent: Bool = true, asElderBigbro: Bool = false) {
        self.init(refNode, tex: Texture.white, x, y, height, lambda: lambda,
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
        if strTex.name.isShortEmoji {
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
        if tex.name.isShortEmoji {
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
        if tex.name.isShortEmoji {
            piu.color = Color.white
        } else {
            piu.color = Color.black
        }
	}
	/** "Convenience function": Remplace la texture actuel pour une texture de string constant (non mutable). */
    func updateTextureToConstantString(_ newString: String, fontname: String? = nil) {
		tex = Texture.getConstantString(newString, fontname: fontname)
        if tex.name.isShortEmoji {
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

/** Surface avec une mesh "FanMesh" pour afficher une section de disque. */
class ProgressDisk: TiledSurface {
    @discardableResult
    init(_ refNode: Node?, pngTex: Texture,
                  _ x: Float, _ y: Float, _ height: Float,
                  lambda: Float = 0, i: Int = 0, flags: Int = 0,
                  asParent: Bool = true, asElderBigbro: Bool = false
    ) {
        super.init(refNode, pngTex: pngTex, x, y, height, lambda: lambda, i: i, flags: flags,
                   mesh: FanMesh(), asParent: asParent, asElderBigbro: asElderBigbro)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    func updateRatio(_ ratio: Float) {
        (self.mesh as! FanMesh).update(with: ratio)
    }
}

/** Disque "timer" qui pop et disparaît après deltaT secondes. */
final class PopDisk : ProgressDisk {
    private var timer1, timer2: Timer!
    private var chrono = ChronoR()
    private let deltaT: Float
    
    @discardableResult
    init?(_ refNode: Node, pngTex: Texture, deltaT: Float, _ x: Float, _ y: Float, _ height: Float,
          lambda: Float, i: Int, flags: Int = 0
    ) {
        self.deltaT = deltaT
        super.init(refNode, pngTex: pngTex, x, y, height,
                   lambda: lambda, i: i, flags: flags)
        updateRatio(0)
        chrono.start()
        self.y.fadeInFromDef(delta: height)
        width.fadeIn(delta: -height * 0.3)
        self.height.fadeIn(delta: -height * 0.3)
        openAndShowBranch()
        
        timer1 = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] (t) in
            guard let self = self else { t.invalidate(); return }
            self.updateRatio(min(self.chrono.elapsedSec / deltaT, 1))
        }
        timer2 = Timer.scheduledTimer(withTimeInterval: Double(deltaT), repeats: false) { [weak self] (t) in
            //guard let self = self else { return }
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
        timer1.invalidate()
        timer2.invalidate()
        closeBranch()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] (_) in
            self?.disconnect()
        }
    }
}

final class PopSurface: TiledSurface {
    @discardableResult
    init?(over ref: Node, pngTex: Texture, time: Double,
         x_rel: Float, y_rel: Float, h_rel: Float,
         lambda: Float = 0, i: Int = 0, flags: Int = 0)
    {
        let sq = Squirrel(at: ref,
                          relPos: Vector2(ref.x.realPos, ref.y.realPos),
                          scaleInit: .deltas)
        while sq.goUpPS() {}
        let w = 2*sq.vS.y
        super.init(PopOver.screen, pngTex: pngTex,
                   sq.v.x + x_rel * w, sq.v.y + y_rel * w, h_rel * w,  // Facteur 2 parce que scale est init sur delta.
                   lambda: lambda, i: i, flags: flags | Flag1.poping)
        openAndShowBranch()
        Timer.scheduledTimer(withTimeInterval: time, repeats: false) { [weak self] (t) in
            self?.closeBranch()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] (_) in
                self?.disconnect()
            }
        }
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
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
