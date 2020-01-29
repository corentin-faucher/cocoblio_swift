extension Node {
    @discardableResult
    func also(_ block: (Node) -> Void) -> Self {
        block(self)
        return self
    }
    /** Ajout d'une surface simple à un noeud racine.
     * Sa hauteur devient 1 et ses scales deviennent sa hauteur. */
    func alsoAddSurf(texEnum: TexEnum, i: Int, flags: Int = 0) -> Self {
        if (firstChild != nil) { printerror("A déjà quelque chose."); return self }
        addFlags(Flag1.getChildSurfaceRatio)
        scaleX.realPos = height.realPos
        scaleY.realPos = height.realPos
        height.realPos = 1
        width.realPos = 1
        Surface(self, texEnum, 0, 0, 1, lambda: 0, i: i, flags: flags)
        
        return self
    }
    /** Ajout d'un frame et string à un noeud.
     * La hauteur devient 1 et ses scales deviennent sa hauteur. Delta est un pourcentage. */
    func alsoAddFrameAndStrCst(_ string: String, _ texEnum: TexEnum,
                               delta: Float = 0.25) -> Self {
        if (firstChild != nil) { printerror("A déjà quelque chose."); return self}
        addFlags(Flag1.getChildSurfaceRatio)
        scaleX.realPos = height.realPos
        scaleY.realPos = height.realPos
        height.realPos = 1
        width.realPos = 1
        
        Frame(self, delta: delta, lambda: 0, texEnum: texEnum)
        SurfStrCst(self, string, 0, 0, 1)
        
        return self
    }
    /** Ajout d'un frame et string à un noeud.
     * La hauteur devient 1 et ses scales deviennent sa hauteur. Delta est un pourcentage. */
    func alsoAddFrameAndStrLoc(_ stringID: String, _ texEnum: TexEnum,
                               delta: Float = 0.25) -> Self {
        if (firstChild != nil) { printerror("A déjà quelque chose."); return self}
        addFlags(Flag1.getChildSurfaceRatio)
        scaleX.realPos = height.realPos
        scaleY.realPos = height.realPos
        height.realPos = 1
        width.realPos = 1
        
        Frame(self, delta: delta, lambda: 0, texEnum: texEnum)
        SurfStrLoc(self, stringID, 0, 0, 1)
        
        return self
    }
    /** Ajout d'un frame et string à un noeud.
     * La hauteur devient 1 et ses scales deviennent sa hauteur. Delta est un pourcentage. */
    func alsoAddFrameAndStrEdt(_ id: Int, _ texEnum: TexEnum,
                               delta: Float = 0.25) -> Self {
        if (firstChild != nil) { printerror("A déjà quelque chose."); return self}
        addFlags(Flag1.getChildSurfaceRatio)
        scaleX.realPos = height.realPos
        scaleY.realPos = height.realPos
        height.realPos = 1
        width.realPos = 1
        
        Frame(self, delta: delta, lambda: 0, texEnum: texEnum)
        SurfStrEdt(self, id, 0, 0, 1)
        
        return self
    }
    
    /** Aligner les descendants d'un noeud. */
    func alignTheChildren(alignOpt: Int, ratio: Float) {
        let sq = Squirrel(at: self)
        if (!sq.goDownToUnhidden()) {printerror("pas de child.");return}
        // 1. Setter largeur/hauteur
        var w: Float = 0
        var h: Float = 0
        var N: Int = 0
        if (alignOpt & AlignOpt.vertically == 0) {
            repeat {
                w += sq.pos.deltaX * 2
                N += 1
                if (sq.pos.deltaY*2 > h) {
                    h = sq.pos.deltaY*2
                }
            } while (sq.goRightToUnhidden())
        } else {
            repeat {
                h += sq.pos.deltaY * 2
                N += 1
                if (sq.pos.deltaX * 2 > w) {
                    w = sq.pos.deltaX * 2
                }
            } while (sq.goRightToUnhidden())
        }
        // 2. Ajuster l'espacement
        var spacing: Float = 0
        if (alignOpt & AlignOpt.respectRatio != 0) {
            if(alignOpt & AlignOpt.vertically == 0) {
                if  (w/h < ratio) {
                    spacing = (ratio * h - w) / Float(N)
                    w = ratio * h
                }
            } else {
                if (w/h > ratio) {
                    spacing = (w/ratio - h) / Float(N)
                    h = w / ratio
                }
            }
        }
        // 3. Setter les dims.
        let fix = (alignOpt & AlignOpt.fixPos != 0)
        let setDef = (alignOpt & AlignOpt.dontSetAsDef == 0)
        if (alignOpt & AlignOpt.dontChangeParSizes == 0) {
            width.setPos(w, fix, setDef)
            height.setPos(h, fix, setDef)
        }
        // 4. Aligner les éléments
        sq.reinit(at: self)
        if (!sq.goDownToUnhidden()) {printerror("pas de child2.");return}
        if(alignOpt & AlignOpt.vertically == 0) {
            var x = -w / 2
            repeat {
                x += sq.pos.deltaX + spacing/2
                
                sq.pos.x.setPos(x, fix, setDef)
                if(setDef) {
                    sq.pos.y.setPos(0, fix, setDef)
                }
                else {
                    sq.pos.y.setToDef()
                }
                x += sq.pos.deltaX + spacing/2
            } while (sq.goRightToUnhidden())
            return
        }
        
        var y = -h / 2
        repeat {
            y += sq.pos.deltaY + spacing/2
            
            if(setDef) {
                sq.pos.x.setPos(0, fix, setDef)
            } else {
                sq.pos.x.setToDef()
            }
            sq.pos.y.setPos(y, fix, setDef)
            
            y += sq.pos.deltaY + spacing / 2
        } while (sq.goRightToUnhidden())
    }
}

enum AlignOpt {
    static let vertically = 1
    static let dontChangeParSizes = 2
    static let respectRatio = 4
    static let fixPos = 8
    static let dontSetAsDef = 16
}