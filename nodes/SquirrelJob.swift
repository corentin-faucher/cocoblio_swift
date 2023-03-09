//
//  SquirrelJob.swift
//  MasaKiokuGameOSX
//
//  Created by Corentin Faucher on 2019-02-11.
//  Copyright © 2019 Corentin Faucher. All rights reserved.
//
import simd
///--- Routines d'écureuils ----

/** Ajouter des flags à une branche (noeud et descendents s'il y en a). */
extension Node {
    func forEachAddFlags(_ flags: Int) {
        addFlags(flags)
        guard let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            sq.pos.addFlags(flags)
            if sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch.")
                    return
                } else if sq.pos === self {return}
            }
        }
    }
    
    /** Retirer des flags à toute la branche (noeud et descendents s'il y en a). */
    func forEachRemoveFlags(_ flags: Int) {
        removeFlags(flags)
        guard let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            sq.pos.removeFlags(flags)
            if sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch.")
                    return
                } else if sq.pos === self {return}
            }
        }
    }
    
    func forEachNodeInBranch(_ block: (Node)->Void) {
        block(self)
        guard let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            block(sq.pos)
            if sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch.")
                    return
                } else if sq.pos === self {return}
            }
        }
    }
    func forEachTypedNodeInBranch<T: Node>(_ block: (T)->Void) {
        if let typed = self as? T {
            block(typed)
        }
        guard let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            if let typed = sq.pos as? T {
                block(typed)
            }            
            if sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch.")
                    return
                } else if sq.pos === self {return}
            }
        }
    }
    
    func forEachTypedChild<T: Node>(_ block: (T) -> Void) {
        guard let firstChild = firstChild else { return }
        let sq = Squirrel(at: firstChild)
        repeat {
            if let typed = sq.pos as? T {
                block(typed)
            }
        } while sq.goRight();
    }
    
    /** Retirer des flags à la loop de frère où se situe le noeud présent.  Inutile ? */
    /*
    func removeBroLoopFlags(_ flags: Int) {
        removeFlags(flags)
        var sq = Squirrel(at: self)
        while sq.goRight() {
            sq.pos.removeFlags(flags)
        }
        sq = Squirrel(at: self)
        while sq.goLeft() {
            sq.pos.removeFlags(flags)
        }
    }
    */
    /** Ajouter/retirer des flags à une branche (noeud et descendents s'il y en a).   Inutile ? */
    /*
    func addRemoveBranchFlags(_ flagsAdded: Int, _ flagsRemoved: Int) {
        addRemoveFlags(flagsAdded, flagsRemoved)
        guard let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            sq.pos.addRemoveFlags(flagsAdded, flagsRemoved)
            if sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch.")
                    return
                } else if sq.pos === self {return}
            }
        }
    }
     */
 
    /** Ajouter un flag aux "parents" (pas au noeud présent). */
    func addRootFlag(_ flag: Int) {
        if parent == nil {
            return
        }
        let sq = Squirrel(at: self)
        while sq.goUp(), !sq.pos.containsAFlag(flag) {
            sq.pos.addFlags(flag)
        }
    }

    /** Flag le noeud comme "selectable" et trace sont chemin dans l'arbre pour être retrouvable. */
    func makeSelectable() {
        addRootFlag(Flag1.selectableRoot)
        addFlags(Flag1.selectable)
    }

    /**  Pour chaque noeud :
     * 1. Applique open (avant d'ajouter "show"),
     * 2. ajoute "show" si non caché,
     * 3. visite si est une branche avec "show".
     * (show peut être ajouté manuellement avant pour afficher une branche cachée)
     * (show peut avoir été ajouté exterieurement) */
    final func openAndShowBranch() {
        self.open()
        if !containsAFlag(Flag1.hidden) {
            addFlags(Flag1.show)
        }
        guard containsAFlag(Flag1.show), let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            sq.pos.open()
            if !sq.pos.containsAFlag(Flag1.hidden) {
                sq.pos.addFlags(Flag1.show)
            }
            if sq.pos.containsAFlag(Flag1.show), sq.goDown() {
                continue
            }
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch."); return
                } else if sq.pos === self {
                    return
                }
            }
        }
    }
    final func unhideAndTryToOpen() {
        removeFlags(Flag1.hidden)
        guard let parent = parent, parent.containsAFlag(Flag1.show) else { return }
        openAndShowBranch()
    }
    
    /// Enlever "show" aux noeud de la branche (sauf les exposed) et appliquer la close().
    func closeBranch() {
        if !containsAFlag(Flag1.exposed) {
            removeFlags(Flag1.show)
        }
        close()
        guard let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            if !sq.pos.containsAFlag(Flag1.exposed) {
                sq.pos.removeFlags(Flag1.show)
            }
            sq.pos.close()
            
            if sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch."); return
                } else if sq.pos === self {return}
            }
        }
    }
    final func hideAndTryToClose() {
        addFlags(Flag1.hidden)
        guard containsAFlag(Flag1.show) else { return }
        closeBranch()
    }
    
    func reshapeBranch() {
        guard containsAFlag(Flag1.show) else { return }
        reshape()
        guard containsAFlag(Flag1.reshapableRoot), let firstChild = firstChild else { return }
        let sq = Squirrel(at: firstChild)
        while true {
            if sq.pos.containsAFlag(Flag1.show) {
                sq.pos.reshape()
                if sq.pos.containsAFlag(Flag1.reshapableRoot), sq.goDown() {
                    continue
                }
            }
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch."); return
                } else if sq.pos === self {return}
            }
        }
    }
    
    /// Recherche d'un noeud selectionnable dans "root". Retourne nil si rien trouvé.
    func searchBranchForSelectable(absPos: Vector2, nodeToAvoid: Node?) -> Node? {
        let relPos = absPos.inReferentialOf(parent)
        return searchBranchForSelectablePrivate(relPos: relPos, nodeToAvoid: nodeToAvoid)
    }
    
    /*-- Private stuff --*/
    private func searchBranchForSelectablePrivate(relPos: Vector2, nodeToAvoid: Node?) -> Node? {
        let sq = Squirrel(at: self, relPos: relPos, scaleInit: .ones)
		guard sq.isIn, sq.pos.containsAFlag(Flag1.show), sq.pos !== nodeToAvoid else { return nil }
		var candidate: Node? = nil
		// 1. Vérif la root
		if sq.pos.containsAFlag(Flag1.selectable) {
			candidate = sq.pos
		}
		// 2. Se placer au premier child
		guard sq.pos.containsAFlag(Flag1.selectableRoot), sq.goDownP() else { return candidate }
		
        while true {
            if sq.isIn, sq.pos.containsAFlag(Flag1.show), sq.pos !== nodeToAvoid {
                // 1. Possibilité trouvé
                if sq.pos.containsAFlag(Flag1.selectable) {
                    candidate = sq.pos
                    if !sq.pos.containsAFlag(Flag1.selectableRoot) {
                        return candidate
                    }
                }
                // 2. Aller en profondeur
                if sq.pos.containsAFlag(Flag1.selectableRoot) {
                    if sq.goDownP() {
                        continue
                    } else {
//                        printdebug("selectableRoot sans descendents ?")
                    }
                }
            }
            // 3. Remonter, si plus de petit-frère
            while !sq.goRight() {
                if !sq.goUpP() {
                    printerror("Pas de root."); return candidate
                } else if sq.pos === self {return candidate}
            }
        }
    }
	
	/** Recherche du premier selectable du type voulu.
	* Le type est déduit par la valeur retournée attendue. */
	func searchBranchForFirstSelectableTyped<T: Node>() -> T? {
		guard containsAFlag(Flag1.show) else {return nil}
		if containsAFlag(Flag1.selectable) {
			if let typed = self as? T {return typed}
		}
		guard containsAFlag(Flag1.selectableRoot), let firstChild = firstChild else {return nil}
		let sq = Squirrel(at: firstChild)
		while true {
			if sq.pos.containsAFlag(Flag1.show) {
				if sq.pos.containsAFlag(Flag1.selectable) {
					if let typed = sq.pos as? T {return typed}
				}
				if sq.pos.containsAFlag(Flag1.selectableRoot), sq.goDown() { continue }
			}
			// 3. Remonter, si plus de petit-frère
			while !sq.goRight() {
				if !sq.goUp() {
					printerror("Pas de branch.")
					return nil
				} else if sq.pos === self {return nil}
			}
		}
	}
	
	func searchBranchForFirstSelectableUsing(_ testIsValid: (Node)->Bool) -> Node? {
		guard containsAFlag(Flag1.show) else {return nil}
		if containsAFlag(Flag1.selectable) {
			if testIsValid(self) { return self }
		}
		guard containsAFlag(Flag1.selectableRoot), let firstChild = firstChild else {return nil}
		let sq = Squirrel(at: firstChild)
		while true {
			if sq.pos.containsAFlag(Flag1.show) {
				if sq.pos.containsAFlag(Flag1.selectable) {
					if testIsValid(sq.pos) { return sq.pos }
				}
				if sq.pos.containsAFlag(Flag1.selectableRoot), sq.goDown() { continue }
			}
			// 3. Remonter, si plus de petit-frère
			while !sq.goRight() {
				if !sq.goUp() {
					printerror("Pas de branch.")
					return nil
				} else if sq.pos === self {return nil}
			}
		}
	}
	
}


