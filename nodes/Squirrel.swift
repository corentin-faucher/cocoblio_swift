//
//  Squirrel.swift
//  MasaKiokuGameOSX
//
//  Created by Corentin Faucher on 2019-01-09.
//  Copyright © 2019 Corentin Faucher. All rights reserved.
//
import simd

class Squirrel {
    enum RelativeScaleInit {
        case ones
        case scales
		case deltas
    }
    /*-- Données de bases et computed properties --*/
    /// Position dans l'arbre (noeud) de l'écureuil.
    private(set) var pos: Node
    private let root: Node
    // La position en mémoire est dans le référentiel de pos.parent. (pas de changement lors de goRight/goLeft)
    private(set) var v: Vector2
    private(set) var vS: Vector2
    /// Vérifie si on tombe dans le cadre du noeud présent (pos).
    var isIn: Bool {
        return (fabsf(v.x - pos.x.realPos) <= pos.deltaX) &&
            (fabsf(v.y - pos.y.realPos) <= pos.deltaY)
    }
    /** Convertir une position en position relative par rapport
     *  a la position présente (et scaling présent) */
    func getRelPosOf(_ pos: Vector2) -> Vector2 {
        return Vector2((pos.x - v.x) / vS.x, (pos.y - v.y) / vS.y)
    }
    func getRelDeltaOf(_ delta: Vector2) -> Vector2 {
        return Vector2(delta.x / vS.x, delta.y / vS.y)
    }
    
    /*-- Constructeurs... --*/
    init(at pos: Node) {
        self.pos = pos
        root = pos
        v = Vector2(pos.x.realPos, pos.y.realPos)
        vS = Vector2(1,1)
    }
    init(at pos: Node, scaleInit: RelativeScaleInit) {
        self.pos = pos
        root =  pos
        v = Vector2(pos.x.realPos, pos.y.realPos)
        switch scaleInit {
        	case .ones: vS = Vector2(1,1)
        	case .scales: vS = Vector2(pos.scaleX.realPos, pos.scaleY.realPos)
            //        case .sizes: vS = Vector2(pos.width.realPos, pos.height.realPos)
			case .deltas: vS = Vector2(pos.deltaX, pos.deltaY)
        }
    }
    /// Initialise avec une position relative au lieu de la position du noeud.
    /// La postion relative est dans le reférentiel de pos.parent (comme l'est la position du noeud).
    init(at pos: Node, relPos: Vector2, scaleInit: RelativeScaleInit) {
        self.pos = pos
        root = pos
        v = relPos
        switch scaleInit {
        case .ones: vS = Vector2(1,1)
        case .scales: vS = Vector2(pos.scaleX.realPos, pos.scaleY.realPos)
            //        case .sizes: vS = Vector2(pos.width.realPos, pos.height.realPos)
			case .deltas: vS = Vector2(pos.deltaX, pos.deltaY)
        }
    }
    
    /*--- Déplacements ----*/
    /** Déconnecte où on est et va au petit (par défaut) frère.
     * Si ne peut aller au frère, va au parent.
     * Retourne false si doit aller au parent. */
    func disconnectAndGoToBroOrUp(little: Bool = true) -> Bool {
        let toDelete = pos
        if let bro = (little ? pos.littleBro : pos.bigBro) {
            pos = bro
            toDelete.disconnect()
            return true
        }
        if let parent = pos.parent {
            pos = parent
            toDelete.disconnect()
            return false
        }
        printerror("Ne peut deconnecter, nul part où aller.")
        return false
    }
    /// Va au petit-frère. S'arrête au cadet (et retourne false).
    @discardableResult func goRight() -> Bool {
        guard let littleBro = pos.littleBro else {return false}
        pos = littleBro
        return true
    }
    /// Va au petit-frère. S'il n'existe pas, on le crée.
    func goRightForced<T: Node>(_ copyRef: T) {
        if let theLittleBro = pos.littleBro {
            pos = theLittleBro
        } else {
            let newLittleBro = copyRef.copy()
            newLittleBro.simpleMoveToBro(pos, asBigBro: false)
            pos = newLittleBro
        }
    }
    /// Revient à l'ainé si arrive en bout de liste (retourne false si ne peut pas y aller, i.e. pas de parent).
    @discardableResult func goRightLoop() -> Bool {
        guard let littleBro = pos.littleBro else {
            guard let elder = pos.parent?.firstChild else {return false}
            pos = elder
            return true
        }
        pos = littleBro
        return true
    }
    /** Tant que l'on est sur un noeud caché, on bouge vers la droite. Retourne false si abouti en bout de liste.
     * Se déplace au moins une fois. */
    func goRightWithout(flag: Int) -> Bool {
        repeat {
            if !goRight() {return false}
        } while pos.containsAFlag(flag)
        return true
    }
    /// Va au grand-frère. S'arrête et retourne false si ne peut y aller (dépassé l'ainé)
    @discardableResult func goLeft() -> Bool {
        guard let bigBro = pos.bigBro else {return false}
        pos = bigBro
        return true
    }
    func goLeftForced<T: Node>(_ copyRef: T) {
        if let theBigBro = pos.bigBro {
            pos = theBigBro
        } else {
            let newBigBro = copyRef.copy()
            newBigBro.simpleMoveToBro(pos, asBigBro: true)
            pos = newBigBro
        }
    }
    func goLeftWithout(flag: Int) -> Bool {
        repeat {
            if !goLeft() {return false}
        } while pos.containsAFlag(flag)
        return true
    }
    
    /// Va au firstChild. Retourne false si pas de descendants.
    @discardableResult func goDown() -> Bool {
        guard let firstChild = pos.firstChild else {return false}
        pos = firstChild
        return true
    }
    /// Va au firstChild. S'il n'existe pas on le crée.
    func goDownForced<T: Node>(_ copyRef: T) {
        if let theFirstChild = pos.firstChild {
            pos = theFirstChild
        } else {
            let newFirstChild = copyRef.copy()
            newFirstChild.simpleMoveToParent(pos, asElder: true)
            pos = newFirstChild
        }
    }
    
    /** Va au lastChild. Retourne false si pas de descendants. */
    func goDownLast() -> Bool {
        guard let lastChild = pos.lastChild else {return false}
        pos = lastChild
        return true
    }
    func goDownWithout(flag: Int) -> Bool {
        guard let firstChild = pos.firstChild else {return false}
        pos = firstChild
        while pos.containsAFlag(flag) {
            if !goRight() {return false}
        }
        return true
    }
    func goDownLastWithout(flag: Int) -> Bool {
        guard let lastChild = pos.lastChild else {return false}
        pos = lastChild
        while pos.containsAFlag(flag) {
            if !goLeft() {return false}
        }
        return true
    }
    func goDownP() -> Bool {
        guard let firstChild = pos.firstChild else {return false}
        v.x = (v.x - pos.x.realPos) / pos.scaleX.realPos
        v.y = (v.y - pos.y.realPos) / pos.scaleY.realPos
        pos = firstChild
        return true
    }
    func goDownPS() -> Bool {
        guard let firstChild = pos.firstChild else {return false}
        v.x = (v.x - pos.x.realPos) / pos.scaleX.realPos
        v.y = (v.y - pos.y.realPos) / pos.scaleY.realPos
        vS.x /= pos.scaleX.realPos
        vS.y /= pos.scaleY.realPos
        pos = firstChild
        return true
    }
    @discardableResult func goUp() -> Bool {
        guard let parent = pos.parent else {return false}
        pos = parent
        return true
    }
    func goUpP() -> Bool {
        guard let parent = pos.parent else {return false}
        pos = parent
        v.x = v.x * pos.scaleX.realPos + pos.x.realPos
        v.y = v.y * pos.scaleY.realPos + pos.y.realPos
        return true
    }
    func goUpPS() -> Bool {
        guard let parent = pos.parent else {return false}
        pos = parent
        v.x = v.x * pos.scaleX.realPos + pos.x.realPos
        v.y = v.y * pos.scaleY.realPos + pos.y.realPos
        vS.x *= pos.scaleX.realPos
        vS.y *= pos.scaleY.realPos
        return true
    }
    func goToNextNode() -> Bool {
		if goDown() { return true }
        while !goRight() {
            if !goUp() {
                printerror("Pas de root.")
                return false
			} else {
				if pos === root {
					return false
				}
            }
        }
        return true
    }
    
    func goToNextToDisplay() -> Bool {
        // 1. Aller en profondeur, pause si branche à afficher.
        if pos.firstChild != nil, pos.containsAFlag(Flag1.show|Flag1.branchToDisplay) {
            pos.removeFlags(Flag1.branchToDisplay)
            goDown()
            return true
        }
        // 2. Redirection (voisin, parent).
        repeat {
            // Si le noeud présent est encore actif -> le parent doit l'être aussi.
            if pos.isDisplayActive() {
                pos.parent?.addFlags(Flag1.branchToDisplay)
            }
            if goRight() {return true}
        } while goUp()
        return false
    }
}



