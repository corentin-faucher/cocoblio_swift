

protocol Surface2 : Node {
	var tex: Texture { get }
	var mesh: Mesh { get }
	var trShow: SmTrans { get set }
	func updateRatio(fix: Bool)
}

extension Surface2 {
	/** S'il n'y a pas le flag surfaceDontRespectRatio, la largeur est ajustée.
	* Sinon, on ne fait que vérifier le frame voisin
	* et le parent. */
	func updateRatio(fix: Bool) {
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

class StringSurface: Node, Surface2, Openable {
	private(set) var tex: Texture
	let mesh: Mesh = .sprite
	var trShow: SmTrans = SmTrans()
	
	/** On prend pour aquis que la texture reçu est déjà une texture avec une string. */
	@discardableResult
	init(_ refNode: Node?, strTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
		 flags: Int = 0, ceiledWidth: Float? = nil,
		 asParent: Bool = true, asElderBigbro: Bool = false
	) {
		guard strTex.isString else {
			printerror("Pas une texture de string")
			tex = Texture.defaultString
			super.init(refNode, x, y, ceiledWidth ?? height, height, lambda: lambda, flags: flags, asParent: asParent, asElderBigbro: asElderBigbro)
			return
		}
		tex = strTex
		super.init(refNode, x, y, height, height, lambda: lambda, flags: flags, asParent: asParent, asElderBigbro: asElderBigbro)
		if ceiledWidth != nil {
			addFlags(Flag1.surfaceWithCeiledWidth)
		}
		piu.color = [0, 0, 0, 1] // (Text noir par défaut.)
		updateRatio(fix: true)
	}
	required init(other: Node) {
		tex = (other as! StringSurface).tex
		super.init(other: other)
	}
	func open() {
		updateRatio(fix: true)
	}
	/** Change la texture du noeud (dervrait être une string). */
	func updateTexture(_ newTexture: Texture, fix: Bool) {
		guard newTexture.isString else {
			printerror("Not a string texture")
			return
		}
		tex = newTexture
		updateRatio(fix: fix)
	}
	/** Met à jour la string de la texture (qui peut être partagé) et updateRatio. */
	func updateString(_ newString: String, fix: Bool) {
		guard tex.isMutable else {
			printerror("Not a mutable string texture")
			return
		}
		tex.updateString(newString)
		updateRatio(fix: fix)
	}
}

/** Surface avec tiles (e.g. ensemble de 4x4 icones dans un png.) */
class TiledSurface: Node, Surface2 {
	private(set) var tex: Texture
	let mesh: Mesh = .sprite
	var trShow: SmTrans = SmTrans()
	
	@discardableResult
	init(_ refNode: Node?, pngTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0, i: Int = 0,
		 flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false
	) {
		guard !pngTex.isString else {
			printerror("Pas une texture de string")
			tex = Texture.defaultString
			super.init(refNode, x, y, height, height, lambda: lambda, flags: flags,
					   asParent: asParent, asElderBigbro: asElderBigbro)
			return
		}
		tex = pngTex
		super.init(refNode, x, y, height, height, lambda: lambda, flags: flags,
				   asParent: asParent, asElderBigbro: asElderBigbro)
		updateRatio(fix: true)
		updateTile(i, 0)
	}
	required init(other: Node) {
		tex = (other as! TiledSurface).tex
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
	func updateTexture(_ newTexture: Texture) {
		tex = newTexture
	}
}

class LanguageSurface: Node, Surface2, Openable {
	let tex: Texture
	let mesh: Mesh = .sprite
	var trShow: SmTrans = SmTrans()
	
	@discardableResult
	init(_ refNode: Node?, pngTex: Texture,
		 _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0, i: Int = 0,
		 flags: Int = 0, ceiledWidth: Float? = nil,
		 asParent: Bool = true, asElderBigbro: Bool = false
	) {
		guard !pngTex.isString else {
			printerror("Pas une texture de string")
			tex = Texture.defaultString
			super.init(refNode, x, y, height, height, lambda: lambda, flags: flags,
					   asParent: asParent, asElderBigbro: asElderBigbro)
			return
		}
		tex = pngTex
		super.init(refNode, x, y, height, height, lambda: lambda, flags: flags,
				   asParent: asParent, asElderBigbro: asElderBigbro)
		updateRatio(fix: true)
	}
	required init(other: Node) {
		tex = (other as! StringSurface).tex
		super.init(other: other)
	}
	func open() {
		let i = Language.currentId
		piu.tile = (Float(i % tex.m),
					Float((i / tex.m) % tex.n))
	}
}

class TestFrame : Node, Surface2, Reshapable, Openable {
	let tex: Texture
	let mesh: Mesh = .sprite
	var trShow: SmTrans = SmTrans()
	
	@discardableResult
	init(_ refNode: Node) {
		tex = Texture.testFrame
		super.init(refNode, 0, 0, refNode.width.realPos, refNode.height.realPos, lambda: 10,
				   flags: Flag1.surfaceDontRespectRatio)
	}
	required init(other: Node) {
		tex = (other as! TestFrame).tex
		super.init(other: other)
	}
	
	func open() {
		guard let theParent = parent else { printerror("TestFrame sans parent."); return}
		height.pos = theParent.height.realPos
		width.pos = theParent.width.realPos
	}
	
	func reshape() -> Bool {
		open()
		return false
	}
}

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
