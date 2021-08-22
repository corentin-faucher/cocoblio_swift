

extension Node : KotlinLikeScope {}

extension Node {
    /*-- Ajout de frame --*/
    /** !Debug Option!
     * Ajout d'une surface "frame" pour visualiser la taille d'un "bloc".
     * L'option Node.showFrame doit être "true". */
    func tryToAddFrame() {
        guard Node.showFrame else {return}
        TestFrame(self)
    }
    
    
    /*-- Ajustement de position/taille --*/    
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
    
    func setRelatively(fix: Bool) {
        guard containsAFlag(Flag1.relativeFlags), let theParent = parent else { return }
        var xDec: Float = 0
        var yDec: Float = 0
        if containsAFlag(Flag1.relativeToRight) {
            xDec = theParent.width.realPos * 0.5
        } else if containsAFlag(Flag1.relativeToLeft) {
            xDec = -theParent.width.realPos * 0.5
        }
        if containsAFlag(Flag1.relativeToTop) {
            yDec = theParent.height.realPos * 0.5
        } else if containsAFlag(Flag1.relativeToBottom) {
            yDec = -theParent.height.realPos * 0.5
        }
        if containsAFlag(Flag1.rightJustified) {
            xDec -= deltaX
        } else if containsAFlag(Flag1.leftJustified) {
            xDec += deltaX
        }
        if containsAFlag(Flag1.topJustified) {
            yDec -= deltaY
        } else if containsAFlag(Flag1.bottomJustified) {
            yDec += deltaY
        }
        x.setRelToDef(shift: xDec, fix: fix)
        y.setRelToDef(shift: yDec, fix: fix)
    }
    
    /** Aligner les descendants d'un noeud. */
    @discardableResult
    func alignTheChildren(alignOpt: Int, ratio: Float = 1, spacingRef: Float = 1) -> Int {
        var sq = Squirrel(at: self)
        guard sq.goDownWithout(flag: Flag1.hidden|Flag1.notToAlign) else {
            printerror("pas de child."); return 0
        }
        // 0. Les options
        let fix = (alignOpt & AlignOpt.fixPos != 0)
        let horizontal = (alignOpt & AlignOpt.vertically == 0)
        let setAsDef = (alignOpt & AlignOpt.setAsDefPos != 0)
        let setSecondaryToDefPos = (alignOpt & AlignOpt.setSecondaryToDefPos != 0)
        // 1. Mesurer largeur et hauteur requises
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
			} while sq.goRightWithout(flag: Flag1.hidden|Flag1.notToAlign)
        } else {
            repeat {
                h += sq.pos.deltaY * 2 * spacingRef
                n += 1
                if (sq.pos.deltaX * 2 > w) {
                    w = sq.pos.deltaX * 2
                }
            } while sq.goRightWithout(flag: Flag1.hidden|Flag1.notToAlign)
        }
        // 2. Calculer l'espacement requis et ajuster w/h en fonction du ratio voulu.
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
        // 3. Mettre à jour largeur et hauteur du noeud parent.
        if (alignOpt & AlignOpt.dontUpdateSizes == 0) {
            width.set(w, fix, setAsDef)
            height.set(h, fix, setAsDef)
			if containsAFlag(Flag1.giveSizesToBigBroFrame), let frame = bigBro as? Frame {
				frame.update(width: w, height: h, fix: fix)
			}
        }
        // 4. Aligner les éléments
        sq = Squirrel(at: self)
        guard sq.goDownWithout(flag: Flag1.hidden|Flag1.notToAlign) else {
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
            } while (sq.goRightWithout(flag: Flag1.hidden|Flag1.notToAlign))
            return n
        }
        
        var y = h / 2
        repeat {
            y -= sq.pos.deltaY * spacingRef + spacing/2
            
            sq.pos.y.set(y, fix, setAsDef)
            if setSecondaryToDefPos {
                sq.pos.x.setRelToDef(shift: 0, fix: fix)
            } else {
                sq.pos.x.set(0, fix, false)
            }
            
            y -= sq.pos.deltaY * spacingRef + spacing / 2
        } while (sq.goRightWithout(flag: Flag1.hidden|Flag1.notToAlign))
        
        return n
    }
}

enum AlignOpt {
    static let vertically = 1
    static let dontUpdateSizes = 2
    /** Ajoute de l'espacement supplémentaire entre les élément pour respecter le ratio w/h.
     (Compact si option absente.) */
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
