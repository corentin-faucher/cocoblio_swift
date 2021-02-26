

class Surface: Node {
    var tex: Texture
    var mesh: Mesh
    var trShow: SmTrans
    var trExtra: SmTrans
    
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
    
    required init(other: Node) {
        let otherSurf = other as! Surface
        tex = otherSurf.tex
        mesh = otherSurf.mesh
        trShow = otherSurf.trShow
        trExtra = otherSurf.trExtra
        super.init(other: other)
    }
    
    func updateRatio(fix: Bool) {
        guard !containsAFlag(Flag1.surfaceDontRespectRatio) else {return}
        
        if containsAFlag(Flag1.surfaceWithCeiledWidth) {
            width.set(min(height.realPos * tex.ratio, width.defPos), fix, false)
        } else {
            width.set(height.realPos * tex.ratio, fix, true)
        }
        if containsAFlag(Flag1.giveSizesToBigBroFrame), let bigBroFrame = bigBro as? Frame {
            bigBroFrame.updateWithLittleBro(fix: fix)
        }
        if containsAFlag(Flag1.giveSizesToParent), let theParent = parent  {
            theParent.width.set(width.realPos)
            theParent.height.set(height.realPos)
        }
    }
    
    override func isDisplayActive() -> Bool {
        return trShow.isActive
    }
}


class StringSurface: Surface //, Openable
{
	/** On prend pour aquis que la texture reçu est déjà une texture avec une string. */
	@discardableResult
	init(_ refNode: Node?, strTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
		 flags: Int = 0, ceiledWidth: Float? = nil,
		 asParent: Bool = true, asElderBigbro: Bool = false
	) {
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
			addFlags(Flag1.surfaceWithCeiledWidth)
		}
		piu.color = [0, 0, 0, 1] // (Text noir par défaut.)
		
	}
	@discardableResult
	convenience init(_ refNode: Node?, cstString: String,
					 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
					 flags: Int = 0, ceiledWidth: Float? = nil,
					 asParent: Bool = true, asElderBigbro: Bool = false
	) {
		self.init(refNode, strTex: Texture.getConstantString(cstString),
				  x, y, height, lambda: lambda, flags: flags, //|Flag1.isSurface,
                  ceiledWidth: ceiledWidth,
				  asParent: asParent, asElderBigbro: asElderBigbro)
	}
	required init(other: Node) {
		super.init(other: other)
	}
    override func open() {
		updateRatio(fix: true)
        super.open()
	}
	/** Change la texture du noeud (dervrait être une string). */
	func updateTexture(_ newTexture: Texture) {
        guard newTexture.type != .png else {
			printerror("Not a string texture")
			return
		}
		tex = newTexture
	}
	/** "Convenience function": Ne change pas la texture. Ne fait que mettre à jour la string de la texture. */
	func updateAsMutableString(_ newString: String) {
        guard tex.type == .mutableString else {
			printerror("Not a mutable string texture.")
			return
		}
		tex.updateAsMutableString(newString)
	}
	/** "Convenience function": Remplace la texture actuel pour une texture de string constant (non mutable). */
	func updateTextureToConstantString(_ newString: String) {
		tex = Texture.getConstantString(newString)
	}
}

/** Surface avec tiles (e.g. ensemble de 4x4 icones dans un png.) */
class TiledSurface: Surface {
	@discardableResult
	init(_ refNode: Node?, pngTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0, i: Int = 0,
		 flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false
	) {
        guard pngTex.type == .png else {
			printerror("String texture (need standand texture).")
            super.init(refNode, tex: Texture.defaultPng, x, y, height, lambda: lambda, flags: flags,
                       mesh: .sprite, asParent: asParent, asElderBigbro: asElderBigbro)
			return
		}
        super.init(refNode, tex: pngTex, x, y, height, lambda: lambda, flags: flags,
                   mesh: .sprite, asParent: asParent, asElderBigbro: asElderBigbro)
		updateRatio(fix: true)
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
	/** Ne change que la texture (pas de updateRatio). */
	func updateTexture(_ newTexture: Texture) {
        guard newTexture.type == .png else {
			printerror("Not a png texture.")
			return
		}
		tex = newTexture
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
		updateRatio(fix: true)
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
	
	override func reshape() -> Bool {
		open()
		return false
	}
}

// GARBAGE

//protocol Surface : Node {
//    var tex: Texture { get }
//    var mesh: Mesh { get }
//    var trShow: SmTrans { get set }
//    var trExtra: SmTrans { get set }
//    func updateRatio(fix: Bool)
//}

//protocol FlippableSurface {
//    var trFlip: SmTrans { get set }
//}

//extension Surface {
//    /** S'il n'y a pas le flag surfaceDontRespectRatio, la largeur est ajustée.
//    * Sinon, on ne fait que vérifier le frame voisin
//    * et le parent. */
//    func updateRatio(fix: Bool) {
//        guard !containsAFlag(Flag1.surfaceDontRespectRatio) else {return}
//
//        if containsAFlag(Flag1.surfaceWithCeiledWidth) {
//            width.set(min(height.realPos * tex.ratio, width.defPos), fix, false)
//        } else {
//            width.set(height.realPos * tex.ratio, fix, false)
//        }
//        if containsAFlag(Flag1.giveSizesToBigBroFrame), let bigBroFrame = bigBro as? Frame {
//            bigBroFrame.updateWithLittleBro(fix: fix)
//        }
//        if containsAFlag(Flag1.giveSizesToParent), let theParent = parent  {
////            print("giveng size to parent.")
//            theParent.width.set(width.realPos)
//            theParent.height.set(height.realPos)
//        }
//    }
//}

//class MeshSurface : Surface_ {
//    let tex: Texture
//    var mesh: Mesh
//    var trShow: SmTrans
//    var trExtra = SmTrans()
//
//    @discardableResult
//    init(_ refNode: Node?, texture: Texture, mesh: Mesh,
//         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0, i: Int = 0,
//         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false
//    ) {
//        tex = texture
//        self.mesh = mesh
//        trShow = SmTrans()
//        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags|Flag1.isSurface,
//                   asParent: asParent, asElderBigbro: asElderBigbro)
//    }
//    required init(other: Node) {
//        let otherSurf = other as! MeshSurface
//        tex = otherSurf.tex
//        mesh = otherSurf.mesh
//        trShow = otherSurf.trShow
//        super.init(other: other)
//    }
//
//    func updateRatio(fix: Bool) {
//        printwarning("No updateRatio for MeshSurface.")
//    }
//}
/*
class Surface : Node {
var tex: Texture
let mesh: Mesh
var trShow: SmTrans

/** Init comme une surface ordinaire (png) */
@discardableResult
init(_ refNode: Node?, pngID: String,
_ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
i: Int = 0, flags: Int = 0,
asParent: Bool = true, asElderBigbro: Bool = false, mesh: Mesh = Mesh.sprite) {
self.tex = Texture.getPngTex(pngID: pngID)
self.mesh = mesh
self.trShow = SmTrans()
super.init(refNode, x, y, height, height, lambda: lambda,
flags: flags, asParent: asParent, asElderBigbro: asElderBigbro)
updateTile(i, 0)
updateRatio()
}
/** Init avec la texture directement. */
init(_ refNode: Node?, texture: Texture,
_ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
i: Int = 0, flags: Int = 0, ceiledWidth: Float? = nil,
asParent: Bool = true, asElderBigbro: Bool = false, mesh: Mesh = Mesh.sprite) {
self.tex = texture
self.mesh = mesh
self.trShow = SmTrans()
super.init(refNode, x, y, ceiledWidth ?? height, height, lambda: lambda,
flags: flags, asParent: asParent, asElderBigbro: asElderBigbro)
if ceiledWidth != nil {
addFlags(Flag1.surfaceWithCeiledWidth)
}
updateTile(i, 0)
updateRatio()
}
required init(other: Node) {
let otherSurf = other as! Surface
tex = otherSurf.tex
mesh = otherSurf.mesh
trShow = SmTrans()
super.init(other: other)
}

func updateForTex(pngID: String) {
self.tex = Texture.getPngTex(pngID: pngID)
updateRatio()
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
/** S'il n'y a pas le flag surfaceDontRespectRatio, la largeur est ajustée.
* Sinon, on ne fait que vérifier le frame voisin
* et le parent. */
func updateRatio(fix: Bool = true) {
if !containsAFlag(Flag1.surfaceDontRespectRatio) {
if containsAFlag(Flag1.surfaceWithCeiledWidth) {
width.set(min(height.realPos * tex.ratio, width.defPos), fix, false)
} else {
width.set(height.realPos * tex.ratio, fix, true)
}
}
if containsAFlag(Flag1.giveSizesToBigBroFrame), let bigBroFrame = bigBro as? Frame {
bigBroFrame.update(width: width.realPos, height: height.realPos, fix: true)
}
if containsAFlag(Flag1.giveSizesToParent), let theParent = parent  {
theParent.width.set(width.realPos)
theParent.height.set(height.realPos)
}
}
}

class LanguageSurface : Surface, Openable {
func open() {
print("Opening a LanguageSurface")
updateTile(Language.currentId, 0)
}
// (C'est tout! on garde le reste comme Surface)
}

/** Surface d'une string constante. (non localisée, définie "on the fly".) */
final class CstStrSurf : Surface {
@discardableResult
init(_ refNode: Node?, string: String,
_ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
flags: Int = 0, ceiledWidth: Float? = nil,
asParent: Bool = true, asElderBigbro: Bool = false) {
super.init(refNode, texture: Texture.getConstantStringTex(string: string),
x, y, height, lambda: lambda, i: 0,
flags: flags, ceiledWidth: ceiledWidth,
asParent: asParent, asElderBigbro: asElderBigbro)
piu.color = [0, 0, 0, 1] // (Text noir par défaut.)
}
required init(other: Node) {
super.init(other: other)
}
/** Changement pour une autre string constante. */
func updateForCstStr(newString: String) {
tex = Texture.getConstantStringTex(string: newString)
updateRatio()
}
}

/** Surface d'une string localisable.
* (ne garde en mémoire ni la string ni la locStrID) */
final class LocStrSurf : Surface, Openable {
@discardableResult
init(_ refNode: Node?, stringID: String,
_ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
flags: Int = 0, ceiledWidth: Float? = nil,
asParent: Bool = true, asElderBigbro: Bool = false) {
super.init(refNode, texture: Texture.getLocalizedStringTex(textID: stringID),
x, y, height, lambda: lambda, i: 0,
flags: flags, ceiledWidth: ceiledWidth,
asParent: asParent, asElderBigbro: asElderBigbro)
piu.color = [0, 0, 0, 1] // (Text noir par défaut.)
}
required init(other: Node) {
super.init(other: other)
}

func open() {
updateRatio()
}
/** Changement d'une string localisée. */
func updateForLocStr(stringID: String) {
self.tex = Texture.getLocalizedStringTex(textID: stringID)
updateRatio()
}
}

final class EdtStrSurf : Surface, Openable {
@discardableResult
init(_ refNode: Node?, id: Int,
_ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
flags: Int = 0, ceiledWidth: Float? = nil,
asParent: Bool = true, asElderBigbro: Bool = false) {
super.init(refNode, texture: Texture.getEditableStringTex(id: id),
x, y, height, lambda: lambda, i: 0,
flags: flags, ceiledWidth: ceiledWidth,
asParent: asParent, asElderBigbro: asElderBigbro)
piu.color = [0, 0, 0, 1] // (Text noir par défaut.)
}
init(_ refNode: Node?, id: Int, with string: String,
_ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
flags: Int = 0, ceiledWidth: Float? = nil,
asParent: Bool = true, asElderBigbro: Bool = false) {
super.init(refNode, texture: Texture.getEditableStringTex(id: id),
x, y, height, lambda: lambda, i: 0,
flags: flags, ceiledWidth: ceiledWidth,
asParent: asParent, asElderBigbro: asElderBigbro)
piu.color = [0, 0, 0, 1] // (Text noir par défaut.)
Texture.setEditableString(id: id, newString: string)
}
required init(other: Node) {
super.init(other: other)
}
func open() {
updateRatio()
}
/** Changement pour une autre string editable */
func updateForEdtStr(id: Int) {
self.tex = Texture.getEditableStringTex(id: id)
updateRatio()
}
func update() {
updateRatio()
}
}
*/
