

protocol KotlinLikeScope {}

extension KotlinLikeScope {
    @discardableResult
    @inline(__always) func also(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
    @discardableResult
    @inline(__always) func `let`<R>(_ block: (Self) -> R) -> R {
        return block(self)
    }
}

extension Optional where Wrapped: KotlinLikeScope {
    @inline(__always) func also(_ block: (Wrapped) -> Void) -> Self? {
        guard let self = self else {return nil}
        block(self)
        return self
    }
    @inline(__always) func `let`<R>(_ block: (Wrapped) -> R) -> R? {
        guard let self = self else {return nil}
        return block(self)
    }
}

extension Node : KotlinLikeScope {}

extension Node {
    /** Rempli un noeud avec une surface. (e.g. remplir un bouton.) */
    func fillWithSurface(_ pngId: String, i: Int = 0) {
        guard firstChild == nil else { printerror("A déjà quelque chose."); return }
        
        scaleX.set(height.realPos)
        scaleY.set(height.realPos)
        width.set(1)
        height.set(1)
        Surface(self, pngID: pngId, 0, 0, 1, lambda: 0,
                i: i, flags: Flag1.giveSizesToParent)
    }
    /** Rempli un noeud avec une languageSurface . (e.g. remplir un bouton.) */
    func fillWithLanguageSurface(_ pngId: String) {
        guard firstChild == nil else { printerror("A déjà quelque chose."); return }
        
        scaleX.set(height.realPos)
        scaleY.set(height.realPos)
        width.set(1)
        height.set(1)
        LanguageSurface(self, pngID: pngId, 0, 0, 1, lambda: 0,
                i: 0, flags: Flag1.giveSizesToParent)
    }
    
    /** Ajout d'un frame et string à un noeud. (e.g. remplir un bouton.)
    * La hauteur devient 1 et ses scales deviennent sa hauteur.
    * (Pour avoir les objets (label...) relatif au noeud.)
    * Delta est un pourcentage de la hauteur. */
    func fillWithFrameAndLocStr(_ locStrId: String, framePngId: String = "frame_mocha",
                                ceiledWidth: Float? = nil, delta: Float = 0.4) {
        guard firstChild == nil else { printerror("A déjà quelque chose."); return }
        
        scaleX.set(height.realPos)
        scaleY.set(height.realPos)
        let scaleCeiledWidth = (ceiledWidth != nil) ? ceiledWidth! / height.realPos : nil
        width.set(1)
        height.set(1)
        Frame(self, isInside: false, delta: delta, lambda: 0,
              framePngID: framePngId, flags: Flag1.giveSizesToParent)
        LocStrSurf(self, stringID: locStrId, 0, 0, 1, lambda: 0,
                   flags:Flag1.giveSizesToBigBroFrame, ceiledWidth: scaleCeiledWidth)
    }
    func fillWithFrameAndEdtStr(_ edtStrId: Int, framePngId: String = "frame_mocha",
                                delta: Float = 0.4, ceiledWidth: Float? = nil) {
        guard firstChild == nil else { printerror("A déjà quelque chose."); return }
        
        scaleX.set(height.realPos)
        scaleY.set(height.realPos)
        let scaleCeiledWidth = (ceiledWidth != nil) ? ceiledWidth! / height.realPos : nil
        width.set(1)
        height.set(1)
        Frame(self, isInside: false, delta: delta, lambda: 0,
              framePngID: framePngId, flags: Flag1.giveSizesToParent)
        EdtStrSurf(self, id: edtStrId, 0, 0, 1, lambda: 0,
                   flags:Flag1.giveSizesToBigBroFrame, ceiledWidth: scaleCeiledWidth)
    }
    
    func addSurface(_ pngId: String, _ x: Float, _ y: Float, _ height: Float,
                    lambda: Float = 0, i: Int = 0, flags: Int = 0) {
        Surface(self, pngID: pngId, x, y, height,
                lambda: lambda, i: i, flags: flags)
    }
    func addFramedLocStr(_ locStrId: String, framePngId: String,
                         _ x: Float, _ y: Float, _ height: Float,
                         lambda: Float = 0, flags: Int = 0,
                         ceiledWidth: Float? = nil, delta: Float = 0.4) {
        Node(self, x, y, ceiledWidth ?? height, height,
             lambda: lambda, flags: flags).also { nd in
                nd.fillWithFrameAndLocStr(locStrId, framePngId: framePngId, ceiledWidth: ceiledWidth, delta: delta)
        }
    }
    
    /** !Debug Option!
     * Ajout d'une surface "frame" pour visualiser la taille d'un "bloc".
     * L'option Node.showFrame doit être "true". */
    func tryToAddFrame() {
        guard Node.showFrame else {return}
        TestFrame(self)
    }
    
    
    func adjustWidthAndHeightFromChildren() {
        var w: Float = 0
        var h: Float = 0
        var htmp: Float
        var wtmp: Float
        let sq = Squirrel(at: self)
        if !sq.goDownWithout(flag: Flag1.hidden) { return}
        repeat {
            htmp = (sq.pos.deltaY + abs(sq.pos.y.realPos)) * 2
            if (htmp > h) {
                h = htmp
            }
            wtmp = (sq.pos.deltaX + abs(sq.pos.x.realPos)) * 2
            if (wtmp > w) {
                w = wtmp
            }
        } while (sq.goRightWithout(flag: Flag1.hidden))
        width.set(w)
        height.set(h)
    }
    
    /** Aligner les descendants d'un noeud. */
    @discardableResult
    func alignTheChildren(alignOpt: Int, ratio: Float = 1, spacingRef: Float = 1) -> Int {
        var sq = Squirrel(at: self)
        guard sq.goDownWithout(flag: Flag1.hidden) else {
            printerror("pas de child."); return 0
        }
        // 0. Les options
        let fix = (alignOpt & AlignOpt.fixPos != 0)
        let horizontal = (alignOpt & AlignOpt.vertically == 0)
        let setAsDef = (alignOpt & AlignOpt.setAsDefPos != 0)
        let setSecondaryToDefPos = (alignOpt & AlignOpt.setSecondaryToDefPos != 0)
        // 1. Setter largeur/hauteur
        var w: Float = 0
        var h: Float = 0
        var n: Int = 0
        if (horizontal) {
            repeat {
                w += sq.pos.deltaX * 2 * spacingRef
                n += 1
                if (sq.pos.deltaY*2 > h) {
                    h = sq.pos.deltaY*2
                }
            } while sq.goRightWithout(flag: Flag1.hidden)
        } else {
            repeat {
                h += sq.pos.deltaY * 2 * spacingRef
                n += 1
                if (sq.pos.deltaX * 2 > w) {
                    w = sq.pos.deltaX * 2
                }
            } while sq.goRightWithout(flag: Flag1.hidden)
        }
        // 2. Ajuster l'espacement
        var spacing: Float = 0
        if (alignOpt & AlignOpt.respectRatio != 0) {
            if(horizontal) {
                if  (w/h < ratio) {
                    spacing = (ratio * h - w) / Float(n)
                    w = ratio * h
                }
            } else {
                if (w/h > ratio) {
                    spacing = (w/ratio - h) / Float(n)
                    h = w / ratio
                }
            }
        }
        // 3. Setter les dims.
        if (alignOpt & AlignOpt.dontUpdateSizes == 0) {
            width.set(w, fix, setAsDef)
            height.set(h, fix, setAsDef)
        }
        // 4. Aligner les éléments
        sq = Squirrel(at: self)
        guard sq.goDownWithout(flag: Flag1.hidden) else {
            printerror("pas de child2.");return 0
            
        }
        if(horizontal) {
            var x = -w / 2
            repeat {
                x += sq.pos.deltaX * spacingRef + spacing/2
                
                sq.pos.x.set(x, fix, setAsDef)
                if setSecondaryToDefPos {
                    sq.pos.y.setRelToDef(shift: 0, fix: fix)
                } else {
                    sq.pos.y.set(0, fix, false)
                }
                
                x += sq.pos.deltaX * spacingRef + spacing/2
            } while (sq.goRightWithout(flag: Flag1.hidden))
            return n
        }
        
        var y = -h / 2
        repeat {
            y += sq.pos.deltaY * spacingRef + spacing/2
            
            sq.pos.y.set(y, fix, setAsDef)
            if setSecondaryToDefPos {
                sq.pos.x.setRelToDef(shift: 0, fix: fix)
            } else {
                sq.pos.x.set(0, fix, false)
            }
            
            y += sq.pos.deltaY * spacingRef + spacing / 2
        } while (sq.goRightWithout(flag: Flag1.hidden))
        
        return n
    }
}

enum AlignOpt {
    static let vertically = 1
    static let dontUpdateSizes = 2
    static let respectRatio = 4
    static let fixPos = 8
    /** En horizontal, le "primary" est "x" des children,
     * le "secondary" est "y". (En vertical prim->"y", sec->"x".)
     * Place la position "alignée" comme étant la position par défaut pour le primary des children
     * et pour le width/height du parent. Ne touche pas à defPos du secondary des children. */
    static let setAsDefPos = 16
    /** S'il y a "setSecondaryToDefPos", on place "y" à sa position par défaut,
     * sinon, on le place à zéro. */
    static let setSecondaryToDefPos = 32
}
