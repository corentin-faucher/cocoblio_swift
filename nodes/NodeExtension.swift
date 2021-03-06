

extension Node : KotlinLikeScope {}

extension Node {
    /*-- Ajout de frame --*/
    
	/** Ajout d'un frame et string à un noeud. (e.g. remplir un bouton.)
	* La hauteur devient 1 et ses scales deviennent sa hauteur.
	* (Pour avoir les objets (label...) relatif au noeud.)
	* Delta est un pourcentage de la hauteur.
	* Retourne (seulement) la StringSurface ajoutée. */
	@discardableResult
	func fillWithFramedString(strTex: Texture, frameTex: Texture,
							ceiledWidth: Float? = nil, relDelta: Float = 0.3) -> StringSurface? {
		guard firstChild == nil else { printerror("A déjà quelque chose."); return nil }
        guard strTex.type != .png, frameTex.type == .png else {
			printerror("Bad textures"); return nil
		}
		
		scaleX.set(height.realPos)
		scaleY.set(height.realPos)
        // (les vrais dimension width, height seront setté par le frame)
		let scaleCeiledWidth = (ceiledWidth != nil) ? ceiledWidth! / height.realPos : nil

		Frame(self, delta: relDelta, lambda: 0,
			  texture: frameTex, flags: Flag1.giveSizesToParent)
		let stringSurf = StringSurface(self, strTex: strTex, 0, 0, 1, lambda: 0,
									   flags:Flag1.giveSizesToBigBroFrame, ceiledWidth: scaleCeiledWidth)
		stringSurf.updateRatio(fix: true)
		
		
		return stringSurf
	}
	/** Ajout d'une StringSurface à la position voulue.
	* Struct : root->{frame, string}. Retourne la StringSurface. */
	@discardableResult
	func addFramedString(strTex: Texture, frameTex: Texture,
						 _ x: Float, _ y: Float, _ height: Float,
						 lambda: Float = 0, flags: Int = 0,
						 ceiledWidth: Float? = nil, relDelta: Float = 0.35) -> StringSurface? {
		guard strTex.type != .png, frameTex.type == .png else {
			printerror("Bad textures"); return nil
		}
		let node = Node(self, x, y, ceiledWidth ?? height, height,
			 lambda: lambda, flags: flags)
		return node.fillWithFramedString(strTex: strTex,
										 frameTex: frameTex,
										 ceiledWidth: ceiledWidth, relDelta: relDelta)
	}
	/** Ajout d'une TiledSurface avec Frame.
	* Struct : root->{frame, tiledSurface}. Retourne la TiledSurface. */
	@discardableResult
	func addFramedTiledSurface(surfTex: Texture, frameTex: Texture,
							   _ x: Float, _ y: Float, _ height: Float, i: Int,
						 lambda: Float = 0, flags: Int = 0,
						 delta: Float = 0.4) -> TiledSurface? {
        guard surfTex.type == .png, frameTex.type == .png else {
			printerror("Bad textures"); return nil
		}
		let node = Node(self, x, y, height, height,
						lambda: lambda, flags: flags)
		
		Frame(node, delta: delta * height, lambda: 0,
			  texture: frameTex, flags: Flag1.giveSizesToParent)
		let tiledSurf = TiledSurface(node, pngTex: surfTex, 0, 0, height, i: i, flags: Flag1.giveSizesToBigBroFrame)
		return tiledSurf
	}
	
	
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
