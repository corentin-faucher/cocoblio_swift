class Surface : Node {
    var tex: Texture
    let mesh: Mesh
    var trShow: SmTrans
    
    /** Init comme une surface ordinaire (png) */
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
        i: Int = 0, flags: Int = 0,
        asParent: Bool = true, asElderBigbro: Bool = false, mesh: Mesh = Mesh.sprite) {
        self.tex = texture
        self.mesh = mesh
        self.trShow = SmTrans()
        super.init(refNode, x, y, height, height, lambda: lambda,
                   flags: flags, asParent: asParent, asElderBigbro: asElderBigbro)
        updateTile(i, 0)
        updateRatio()
    }
    
    /** Constructeur de copie. */
    required internal init(refNode: Node?, toCloneNode: Node,
                  asParent: Bool = true, asElderBigbro: Bool = false) {
        let toCloneSurface = toCloneNode as! Surface
        tex = toCloneSurface.tex
        mesh = toCloneSurface.mesh
        trShow = SmTrans()
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
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
    func updateRatio() {
        if !containsAFlag(Flag1.surfaceDontRespectRatio) {
            if containsAFlag(Flag1.surfaceWithCeiledWidth) {
                width.setPos(min(height.realPos * tex.ratio, width.defPos), true, false)
            } else {
                width.setPos(height.realPos * tex.ratio, true, true)
            }
        }
        if containsAFlag(Flag1.giveSizesToBigBroFrame), let bigBroFrame = bigBro as? Frame {
            bigBroFrame.update(width: width.realPos, height: height.realPos, fix: true)
        }
        if containsAFlag(Flag1.giveSizesToParent), let theParent = parent  {
            theParent.width.setPos(width.realPos)
            theParent.height.setPos(height.realPos)
        }
    }
}

class LanguageSurface : Surface, OpenableNode {
    func open() {
        updateTile(Language.currentLanguageID, 0)
    }
    // (C'est tout! on garde le reste comme Surface)
}

/** Surface d'une string constante. (non localisée, définie "on the fly".) */
final class CstStrSurf : Surface {
    init(_ refNode: Node?, _ string: String,
         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false) {
        super.init(refNode, texture: Texture.getConstantStringTex(string: string),
                   x, y, height, lambda: lambda, i: 0, flags: flags,
                   asParent: asParent, asElderBigbro: asElderBigbro)
        piu.color = [0, 0, 0, 1] // (Text noir par défaut.)
    }
    /** Changement pour une autre string constante. */
    func updateForCstStr(newString: String) {
        tex = Texture.getConstantStringTex(string: newString)
        updateRatio()
    }
    
    /** Constructeur de copie. */
    required internal init(refNode: Node?, toCloneNode: Node, asParent: Bool, asElderBigbro: Bool) {
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
}

/** Surface d'une string localisable.
 * (ne garde en mémoire ni la string ni la locStrID) */
final class LocStrSurf : Surface, OpenableNode {
    func open() {
        updateRatio()
    }
    @discardableResult
    init(_ refNode: Node?, _ stringID: String,
         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false) {
        super.init(refNode, texture: Texture.getLocalizedStringTex(textID: stringID),
                   x, y, height, lambda: lambda, i: 0, flags: flags,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
    /** Constructeur de copie. */
    required internal init(refNode: Node?, toCloneNode: Node, asParent: Bool, asElderBigbro: Bool) {
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
}

final class EdtStrSurf : Surface, OpenableNode {
    func open() {
        updateRatio()
    }
    @discardableResult
    init(_ refNode: Node?, id: Int,
         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false) {
        super.init(refNode, texture: Texture.getEditableStringTex(id: id),
                   x, y, height, lambda: lambda, i: 0, flags: flags,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
    init(_ refNode: Node?, id: Int, with string: String,
         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false) {
        super.init(refNode, texture: Texture.getEditableStringTex(id: id),
                   x, y, height, lambda: lambda, i: 0, flags: flags,
                   asParent: asParent, asElderBigbro: asElderBigbro)
        Texture.setEditableString(id: id, newString: string)
    }
    /** Constructeur de copie. */
    required internal init(refNode: Node?, toCloneNode: Node, asParent: Bool, asElderBigbro: Bool) {
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
}