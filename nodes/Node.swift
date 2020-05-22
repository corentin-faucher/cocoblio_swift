//
//  coqNode.swift
//  
//
//  Created by Corentin Faucher on 2018-10-22.
//
import simd

protocol CopyableNode {
    init(other: Self)
}
extension CopyableNode {
    func copy() -> Self {
        return Self.init(other: self)
    }
}

class Node : CopyableNode {
    /*-- Fields --*/
    /** Flags : Les options sur le noeud. */
    private var flags: Int
    
    /** Positions, tailles, etc. */
    var x, y, z, width, height, scaleX, scaleY: SmoothPos
    /** Demi espace occupé en x. (width * scaleX) / 2 */
    var deltaX: Float {
        return width.realPos * scaleX.realPos / 2
    }
    /** Demi espace occupé en y. (height * scaleY) / 2 */
    var deltaY: Float {
        return height.realPos * scaleY.realPos / 2
    }
    
    /** Données d'affichage. */
    var piu : Renderer.PerInstanceUniforms
    
    // Liens
    var firstChild: Node? = nil // Seul firstChild et littleBro sont "strong" pour l'ARC...
    var littleBro: Node? = nil
    weak var parent: Node? = nil
    weak var lastChild: Node? = nil
    weak var bigBro: Node? = nil
    
	
	/*-- Methods --*/
	/** Retirer des flags au noeud. */
	func removeFlags(_ toRemove: Int) {
		flags &= ~toRemove
	}
	/** Ajouter des flags au noeud. */
	func addFlags(_ toAdd: Int) {
		flags |= toAdd
	}
	func addRemoveFlags(_ toAdd: Int, _ toRemove: Int) {
		flags = (flags | toAdd) & ~toRemove
	}
	func containsAFlag(_ flagsRef: Int) -> Bool {
		return (flags & flagsRef) != 0
	}
	func isDisplayActive() -> Bool {
		if let surface = self as? Surface, surface.trShow.isActive {
			return true
		}
		return containsAFlag(Flag1.show | Flag1.branchToDisplay)
	}
    /*-- Fonctions d'accès et Computed properties --*/
    /// Obtenir la position absolue d'un noeud.
    func getAbsPos() -> Vector2 {
        let sq = Squirrel(at: self)
        while sq.goUpP() {}
        return sq.v
    }
	func getPosInGrandPa(_ grandPa: Node) -> Vector2 {
		let sq = Squirrel(at: self)
		repeat {
			if let currentParent = sq.pos.parent,
				currentParent === grandPa
			{
					return sq.v
			}
		} while sq.goUpP()
		printerror("No grandPa encountered.")
		return sq.v
	}
    /** relativePosOf: La position obtenue est dans le référentiel du noeud présent,
     *  i.e. au niveau des node.children.
     * (Si node == nil -> retourne absPos tel quel,
     * cas où node est aNode.parent et parent peut être nul.)*/
    func relativePosOf(absPos: Vector2) -> Vector2 {
        let sq = Squirrel(at: self, scaleInit: .scales)
        while sq.goUpPS() {}
        // Maintenant, sq contient la position absolue de theNode.
        return sq.getRelPosOf(absPos)
    }
    func relativeDeltaOf(absDelta: Vector2) -> Vector2 {
        let sq = Squirrel(at: self, scaleInit: .scales)
        while sq.goUpPS() {}
        return sq.getRelDeltaOf(absDelta)
    }
    /*-- Constructeurs... */
    /** Noeud "vide" et "seul" */
    init(parent: Node?) {
        flags = 0
        x = SmoothPos(0)
        y = SmoothPos(0)
        z = SmoothPos(0)
        width = SmoothPos(4)
        height = SmoothPos(4)
        scaleX = SmoothPos(1)
        scaleY = SmoothPos(1)
        piu = Renderer.PerInstanceUniforms()
        if let theParent = parent {
            connectToParent(theParent, asElder: false)
        }
    }
    /** Création d'un node child/bro. */
    init(_ refNode: Node?,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false) {
        // 1. Données de base
        self.flags = flags
        self.x = SmoothPos(x, lambda)
        self.y = SmoothPos(y, lambda)
        self.z = SmoothPos(0, lambda)
        self.width = SmoothPos(width, lambda)
        self.height = SmoothPos(height, lambda)
        scaleX = SmoothPos(1, lambda)
        scaleY = SmoothPos(1, lambda)
        piu = Renderer.PerInstanceUniforms()
        // 2. Ajustement des références
        if let theRef = refNode {
            if (asParent) {
                connectToParent(theRef, asElder: asElderBigbro)
            } else {
                connectToBro(theRef, asBigbro: asElderBigbro)
            }
        }
    }
    /** Constructeur de copie. */
    required init(other: Node) {
        // 1. Données de base (SmPos et PerInst. sont des struct)
        self.flags = other.flags
        self.x = other.x
        self.y = other.y
        self.z = other.z
        self.width = other.width
        self.height = other.height
        self.scaleX = other.scaleX
        self.scaleY = other.scaleY
        piu = other.piu
    }
    
    /*-----------------------------*/
    /*-- Effacement (decconect) ---*/
    /** Se retire de sa chaine de frère et met les optionals à nil.
     *  Sera effacé par l'ARC, si n'est pas référencié(swift) ou ramassé par le GC?(Kotlin) */
    func disconnect() {
		#warning("Tester: pas de 'deconnexion' et retrait des strong en dernier.")
        // 1. Retrait
        if let theBigBro = bigBro {
            theBigBro.littleBro = littleBro
        } else { // Pas de grand frère -> probablement l'ainé.
            parent?.firstChild = littleBro
        }
        if let theLittleBro = littleBro {
            theLittleBro.bigBro = bigBro
        } else { // Pas de petit frère -> probablement le cadet.
            parent?.lastChild = bigBro
        }

        // 2. Déconnexion
        parent = nil
        littleBro = nil
        bigBro = nil
    }
    /** Deconnexion d'un descendant, i.e. Effacement direct.
     *  Retourne "true" s'il y a un descendant a effacer. */
    @discardableResult func disconnectChild(elder: Bool) -> Bool {
        guard let child = elder ? firstChild : lastChild else {
            return false
        }
        child.disconnect()
        return true
    }
    /// Deconnexion d'un frère, i.e. Effacement direct.
    /// Retourne "true" s'il y a un frère a effacer.
    @discardableResult func disconnectBro(big: Bool) -> Bool {
        guard let bro = big ? bigBro : littleBro else {return false}
        bro.disconnect()
        return true
    }
    
    /*-- Déplacements --*/
    /** Change un frère de place dans sa liste de frère. */
    func moveWithinBrosTo(bro: Node, asBigBro: Bool) {
        if bro === self {return}
        guard let parent = bro.parent, parent === self.parent else {
            printerror("Pas de parent ou pas commun."); return
        }
        // Retrait
        if parent.firstChild === self {
            parent.firstChild = littleBro
        }
        if parent.lastChild === self {
            parent.lastChild = bigBro
        }
        littleBro?.bigBro = bigBro
        bigBro?.littleBro = littleBro
        
        if asBigBro {
            // Insertion
            littleBro = bro
            bigBro = bro.bigBro
            // Branchement
            littleBro?.bigBro = self
            bigBro?.littleBro = self
            if bigBro == nil {
                parent.firstChild = self
            }
        } else {
            // Insertion
            littleBro = bro.littleBro
            bigBro = bro
            // Branchement
            littleBro?.bigBro = self
            bigBro?.littleBro = self
            if littleBro == nil {
                parent.lastChild = self
            }
        }
    }
    func moveAsElderOrCadet(asElder: Bool) {
        // 0. Checks
        if asElder && bigBro == nil {
            return
        }
        if !asElder && littleBro == nil {
            return
        }
        guard let theParent = parent else {
            printerror("Pas de parent."); return
        }
        // 1. Retrait
        if let theBigBro = bigBro {
            theBigBro.littleBro = littleBro
        } else {
            theParent.firstChild = littleBro
        }
        if let theLittleBro = littleBro {
            theLittleBro.bigBro = bigBro
        } else {
            theParent.lastChild = bigBro
        }
        // 2. Insertion
        if asElder {
            bigBro = nil
            littleBro = theParent.firstChild
            // Branchement
            littleBro?.bigBro = self
            theParent.firstChild = self
        } else { // Ajout à la fin de la chaine
            littleBro = nil
            bigBro = theParent.lastChild
            // Branchement
            bigBro?.littleBro = self
            theParent.lastChild = self
        }
        
    }
    /** Change de noeud de place (et ajuste sa position relative). */
    func moveToBro(_ bro: Node, asBigBro: Bool) {
        guard let newParent = bro.parent else {printerror("Bro sans parent."); return}
        setInReferentialOf(node: newParent)
        disconnect()
        connectToBro(bro, asBigbro: asBigBro)
    }
    /** Change de noeud de place (sans ajuster sa position relative). */
    func simpleMoveToBro(_ bro: Node, asBigBro: Bool) {
        disconnect()
        connectToBro(bro, asBigbro: asBigBro)
    }
    /** Change de noeud de place (et ajuste sa position relative). */
    func moveToParent(_ newParent: Node, asElder: Bool) {
        setInReferentialOf(node: newParent)
        disconnect()
        connectToParent(newParent, asElder: asElder)
    }
    /** Change de noeud de place (sans ajuster sa position relative). */
    func simpleMoveToParent(_ newParent: Node, asElder: Bool) {
        disconnect()
        connectToParent(newParent, asElder: asElder)
    }
    /// "Monte" un noeud au niveau du parent. Cas particulier (simplifier) de moveTo(...).
    /// Si c'est une feuille, on ajuste width/height, sinon, on ajuste les scales.
    @discardableResult func moveUp(asBigBro: Bool) -> Bool {
        guard let theParent = parent else {
            printerror("Pas de parent."); return false
        }
        disconnect()
        connectToBro(theParent, asBigbro: asBigBro)
        x.referentialUp(oldParentPos: theParent.x.realPos,
                        oldParentScaling: theParent.scaleX.realPos)
        y.referentialUp(oldParentPos: theParent.y.realPos,
                            oldParentScaling: theParent.scaleY.realPos)
        if firstChild == nil {
            width.referentialUpAsDelta(oldParentScaling: theParent.scaleX.realPos)
            height.referentialUpAsDelta(oldParentScaling: theParent.scaleY.realPos)
        } else {
            scaleX.referentialUpAsDelta(oldParentScaling: theParent.scaleX.realPos)
            scaleY.referentialUpAsDelta(oldParentScaling: theParent.scaleY.realPos)
        }
        return true
    }
    /// "Descend" dans le référentiel d'un frère. Cas particulier (simplifier) de moveTo(...).
    /// Si c'est une feuille, on ajuste width/height, sinon, on ajuste les scales.
    func moveDownIn(bro: Node, asElder: Bool) -> Bool {
        if bro === self {return false}
        guard let oldParent = bro.parent, oldParent === self.parent else {
            printerror("Pas de parent ou pas commun."); return false
        }
        disconnect()
        connectToParent(bro, asElder: asElder)
        
        x.referentialDown(newParentPos: bro.x.realPos, newParentScaling: bro.scaleX.realPos)
        y.referentialDown(newParentPos: bro.y.realPos, newParentScaling: bro.scaleY.realPos)
        
        if firstChild == nil {
            width.referentialDownAsDelta(newParentScaling: bro.scaleX.realPos)
            height.referentialDownAsDelta(newParentScaling: bro.scaleY.realPos)
        } else {
            scaleX.referentialDownAsDelta(newParentScaling: bro.scaleX.realPos)
            scaleY.referentialDownAsDelta(newParentScaling: bro.scaleY.realPos)
        }
        return true
    }
    /// Échange de place avec le "node".
    func permuteWith(_ node: Node) {
        guard let oldParent = parent else {printerror("Manque parent."); return}
        if node.parent == nil {printerror("Manque parent2."); return}
        
        if oldParent.firstChild === self { // Cas ainé...
            moveToBro(node, asBigBro: true)
            node.moveToParent(oldParent, asElder: true)
        } else {
            guard let theBigBro = bigBro else {printerror("Pas de bigBro."); return}
            moveToBro(node, asBigBro: true)
            node.moveToBro(theBigBro, asBigBro: false)
        }
    }
    
    /*-- Private stuff... --*/
    /** Connect au parent. (Doit être fullyDeconnect -> optionals à nil.) */
    private func connectToParent(_ parent: Node, asElder: Bool) {
		#warning("Check aver if let")
        // Dans tout les cas, on a le parent:
        self.parent = parent
        // Cas parent pas d'enfants
        if parent.firstChild == nil {
            parent.firstChild = self
            parent.lastChild = self
            return
        }
        // Ajout au début
        if asElder {
            // Insertion
            self.littleBro = parent.firstChild
            // Branchement
            parent.firstChild!.bigBro = self
            parent.firstChild = self
        } else { // Ajout à la fin de la chaine
            // Insertion
            self.bigBro = parent.lastChild
            // Branchement
            parent.lastChild!.littleBro = self
            parent.lastChild = self
        }
    }
    private func connectToBro(_ bro: Node, asBigbro: Bool) {
        if bro.parent == nil {printerror("Boucle sans parents")}
        parent = bro.parent
        if asBigbro {
            // Insertion
            littleBro = bro
            bigBro = bro.bigBro
            // Branchement
            bro.bigBro = self // littleBro.bigBro = self
            if bigBro != nil {
                bigBro!.littleBro = self
            } else {
                parent?.firstChild = self
            }
        } else {
            // Insertion
            littleBro = bro.littleBro
            bigBro = bro
            // Branchement
            bro.littleBro = self // bigBro.littleBro = self
            if littleBro != nil {
                littleBro!.bigBro = self
            } else {
                parent?.lastChild = self
            }
        }
    }
    /** Change le référentiel. Pour moveTo de node. */
    private func setInReferentialOf(node: Node) {
        let sqP = Squirrel(at: self, scaleInit: .ones)
        while sqP.goUpPS() {}
        let sqQ = Squirrel(at: node, scaleInit: .scales)
        while sqQ.goUpPS() {}
        
        x.newReferential(pos: sqP.v.x, destPos: sqQ.v.x, posScale: sqP.vS.x, destScale: sqQ.vS.x)
        y.newReferential(pos: sqP.v.y, destPos: sqQ.v.y, posScale: sqP.vS.y, destScale: sqQ.vS.y)
        
        if firstChild != nil {
            scaleX.newReferentialAsDelta(posScale: sqP.vS.x, destScale: sqQ.vS.x)
            scaleY.newReferentialAsDelta(posScale: sqP.vS.y, destScale: sqQ.vS.y)
        } else {
            width.newReferentialAsDelta(posScale: sqP.vS.x, destScale: sqQ.vS.x)
            height.newReferentialAsDelta(posScale: sqP.vS.y, destScale: sqQ.vS.y)
        }
    }
    
    // Option de debbuging (ajouter des frame aux noeuds).
    static var showFrame = false
}

