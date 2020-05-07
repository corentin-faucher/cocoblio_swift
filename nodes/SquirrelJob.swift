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
    func addBranchFlags(_ flags: Int) {
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
    func removeBranchFlags(_ flags: Int) {
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
    
    /** Retirer des flags à la loop de frère où se situe le noeud présent. */
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
    
    /** Ajouter/retirer des flags à une branche (noeud et descendents s'il y en a). */
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
     * 1. Applique open pour les openable,
     * 2. ajoute "show" si non caché,
     * 3. visite si est une branche avec "show".
     * (show peut être ajouté manuellement avant pour afficher une branche cachée)
     * (show peut avoir été ajouté exterieurement) */
    func openBranch() {
        (self as? Openable)?.open()
        if !containsAFlag(Flag1.hidden) {
            addFlags(Flag1.show)
        }
        guard containsAFlag(Flag1.show), let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            (sq.pos as? Openable)?.open()
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
    
    /// Enlever "show" aux noeud de la branche (sauf les alwaysShow) et appliquer la "closure".
    func closeBranch() {
        if !containsAFlag(Flag1.exposed) {
            removeFlags(Flag1.show)
            (self as? Closeable)?.close()
        }
        guard let firstChild = firstChild else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            if !sq.pos.containsAFlag(Flag1.exposed) {
                sq.pos.removeFlags(Flag1.show)
                (sq.pos as? Closeable)?.close()
            }
            
            if sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch."); return
                } else if sq.pos === self {return}
            }
        }
    }
    
    func reshapeBranch() {
        guard containsAFlag(Flag1.show), let reshapable = (self as? Reshapable),
            reshapable.reshape(), let firstChild = firstChild
        else {return}
        let sq = Squirrel(at: firstChild)
        while true {
            if sq.pos.containsAFlag(Flag1.show), let reshapable = sq.pos as? Reshapable,
                reshapable.reshape(), sq.goDown() {continue}
            while !sq.goRight() {
                if !sq.goUp() {
                    printerror("Pas de branch."); return
                } else if sq.pos === self {return}
            }
        }
    }
    
    /// Recherche d'un noeud selectionnable dans "root". Retourne nil si rien trouvé.
    func searchBranchForSelectable(absPos: Vector2, nodeToAvoid: Node?) -> Node? {
        let relPos = parent?.relativePosOf(absPos: absPos) ?? absPos
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
                        printerror("selectableRoot sans desc.")
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
	
	func searchBranchForSelectableAndApplyFunction(_ function: (Node)->()) {
		guard containsAFlag(Flag1.show) else {return}
		if containsAFlag(Flag1.selectable) {
			function(self)
		}
		guard containsAFlag(Flag1.selectableRoot), let firstChild = firstChild else {return}
		let sq = Squirrel(at: firstChild)
		while true {
			if sq.pos.containsAFlag(Flag1.show) {
				if sq.pos.containsAFlag(Flag1.selectable) {
					function(sq.pos)
				}
				if sq.pos.containsAFlag(Flag1.selectableRoot), sq.goDown() { continue }
			}
			// 3. Remonter, si plus de petit-frère
			while !sq.goRight() {
				if !sq.goUp() {
					printerror("Pas de branch.")
					return
				} else if sq.pos === self {return}
			}
		}
	}
}


