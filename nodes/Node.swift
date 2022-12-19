//
//  coqNode.swift
//  
//
//  Created by Corentin Faucher on 2018-10-22.
//
import simd

class Node : Copyable, Flagable {
    /*-- Fields --*/
    final var flags: Int
	final let id: Int
    /** Positions, tailles, etc. */
    final var x, y, z, width, height, scaleX, scaleY: SmoothPos
    /** Demi espace occupé en x. (width * scaleX) / 2 */
    final var deltaX: Float {
        return width.realPos * scaleX.realPos / 2
    }
    /** Demi espace occupé en y. (height * scaleY) / 2 */
    final var deltaY: Float {
        return height.realPos * scaleY.realPos / 2
    }
     
    /** Données d'affichage. */
    var piu : Renderer.PerInstanceUniforms
    
    // Liens
    final var firstChild: Node? = nil // Seul firstChild et littleBro sont "strong" pour l'ARC...
    final var littleBro: Node? = nil
    final weak var parent: Node? = nil
    final weak var lastChild: Node? = nil
    final weak var bigBro: Node? = nil
    
	
	/*-- Methods --*/
    /** Vérifie si un noeud / branche doit être parcouru pour l'affichage.
     * Cas particulier de lecture de flags.
     * Définition différente pour les surface (actif plus longtemps, i.e. tant que visible).
     */
    func isDisplayActive() -> Bool {
        return containsAFlag(Flag1.show | Flag1.branchToDisplay)
    }
    /*-- Ouverture/ Fermeture --*/
    /** Open "base" ajuste la position (fading et relativeToParent) */
    func open() {
        guard containsAFlag(Flag1.openFlags) else { return }
        // 1. Set relatively to parent en priorité (incompatible avec FadeIn, les deux utilises x.defPos différemment)
        setRelatively(fix: true)
        // 2. FadeIn, pour l'instant juste en x de la droite.
        if !containsAFlag(Flag1.show), containsAFlag(Flag1.fadeInRight) {
            x.fadeIn()
        }
    }
    func close() {
        // Pour l'instant il n'y a que fadeInRight qui doit être "close".
        if containsAFlag(Flag1.fadeInRight) {
            x.fadeOut()
        }
    }
    func reshape() {
        setRelatively(fix: false)
    }
    /*-- Fonctions d'accès et Computed properties --*/
    /// Obtenir la position absolue (à la racine) d'un noeud.
    final func positionAbsolute() -> Vector2 {
        let sq = Squirrel(at: self)
        while sq.goUpP() {}
        return sq.v
    }
    /// Obtenir la position et dimension absolue (à la racine) d'un noeud.
	final func positionAndDeltaAbsolute() -> (pos: Vector2, deltas: Vector2) {
		let sq = Squirrel(at: self, scaleInit: .deltas)
		while sq.goUpPS() {}
		return (sq.v, sq.vS)
	}
    /// Obtenir la position dans le ref d'un parent (on remonte jusqu'à trouver le parent).
	final func positionInParent(_ par: Node) -> Vector2 {
		let sq = Squirrel(at: self)
		repeat {
			if sq.pos.parent === par {
                return sq.v
			}
		} while sq.goUpP()
		printerror("No parent encountered.")
		return sq.v
	}
    /// Obtenir la position et dimension dans le ref d'un (grand)parent (on remonte jusqu'à trouver le parent).
    final func positionAndDeltaInParent(_ par: Node) -> (pos: Vector2, deltas: Vector2) {
        let sq = Squirrel(at: self, scaleInit: .deltas)
        repeat {
            if sq.pos.parent === par {
                return (sq.v, sq.vS)
            }
        } while sq.goUpPS()
        printerror("No parent encountered.")
        return (sq.v, sq.vS)
    }

    /*-- Constructeurs... */
    /** Noeud "vide" et "seul" (inutile) */
    /*init(parent: Node?) {
		id = Node.nodeCounter
		Node.nodeCounter &+= 1
		
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
    }*/
    /** Création d'un node child/bro. */
    init(_ refNode: Node?,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false) {
		id = Node.nodeCounter
		Node.nodeCounter &+= 1
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
    /** Création d'un node child/bro. version plus complète. Avec z. (z est superflu dans 99% des cas) */
    init(_ refNode: Node?,
         _ x: Float, _ y: Float, _ z: Float, width: Float, height: Float,
         lambda: Float, flags: Int,
         asParent: Bool = true, asElderBigbro: Bool = false)
    {
        id = Node.nodeCounter
        Node.nodeCounter &+= 1
        // 1. Données de base
        self.flags = flags
        self.x = SmoothPos(x, lambda)
        self.y = SmoothPos(y, lambda)
        self.z = SmoothPos(z, lambda)
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
		id = Node.nodeCounter
		Node.nodeCounter &+= 1
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
    final func disconnect() {
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
        // (superflu a priori, mais peux éviter des bogue de double déconnexion si oublie de weak par exemple...)
        parent = nil
        littleBro = nil
        bigBro = nil
    }
    /** Deconnexion d'un descendant, i.e. Effacement direct.
     *  Retourne "true" s'il y a un descendant a effacer. */
    @discardableResult final func disconnectChild(elder: Bool) -> Bool {
        guard let child = elder ? firstChild : lastChild else {
            return false
        }
        child.disconnect()
        return true
    }
    /// Deconnexion d'un frère, i.e. Effacement direct.
    /// Retourne "true" s'il y a un frère a effacer.
    @discardableResult final func disconnectBro(big: Bool) -> Bool {
        guard let bro = big ? bigBro : littleBro else {return false}
        bro.disconnect()
        return true
    }
    
    /*-- Déplacements --*/
    /** Change un frère de place dans sa liste de frère. */
    final func moveWithinBrosTo(bro: Node, asBigBro: Bool) {
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
    final func moveAsElderOrCadet(asElder: Bool) {
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
    final func moveToBro(_ bro: Node, asBigBro: Bool) {
        guard let newParent = bro.parent else {printerror("Bro sans parent."); return}
        setInReferentialOf(node: newParent)
        disconnect()
        connectToBro(bro, asBigbro: asBigBro)
    }
    /** Change de noeud de place (sans ajuster sa position relative). */
    final func simpleMoveToBro(_ bro: Node, asBigBro: Bool) {
        disconnect()
        connectToBro(bro, asBigbro: asBigBro)
    }
    /** Change de noeud de place (et ajuste sa position relative). */
    final func moveToParent(_ newParent: Node, asElder: Bool) {
        setInReferentialOf(node: newParent)
        disconnect()
        connectToParent(newParent, asElder: asElder)
    }
    /** Change de noeud de place (sans ajuster sa position relative). */
    final func simpleMoveToParent(_ newParent: Node, asElder: Bool) {
        disconnect()
        connectToParent(newParent, asElder: asElder)
    }
    /// "Monte" un noeud au niveau du parent. Cas particulier (simplifier) de moveTo(...).
    /// Si c'est une feuille, on ajuste width/height, sinon, on ajuste les scales.
    @discardableResult final func moveUp(asBigBro: Bool) -> Bool {
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
    final func moveDownIn(bro: Node, asElder: Bool) -> Bool {
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
    final func permuteWith(_ node: Node) {
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
    private final func connectToParent(_ parent: Node, asElder: Bool) {
		// Dans tout les cas, on a le parent:
        self.parent = parent
		
		guard let oldParentFirstChild = parent.firstChild,
			let oldParentLastChild = parent.lastChild
		else {
			// Cas parent pas d'enfants
			parent.firstChild = self
			parent.lastChild = self
			return
		}
        // Ajout au début
        if asElder {
            // Insertion
            self.littleBro = oldParentFirstChild
            // Branchement
            oldParentFirstChild.bigBro = self
            parent.firstChild = self
        } else { // Ajout à la fin de la chaine
            // Insertion
            self.bigBro = oldParentLastChild
            // Branchement
            oldParentLastChild.littleBro = self
            parent.lastChild = self
        }
    }
    private final func connectToBro(_ bro: Node, asBigbro: Bool) {
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
    private final func setInReferentialOf(node: Node) {
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
	
	private static var nodeCounter: Int = 0
}

extension Vector2 {
    /** relativePosOf: La position obtenue est dans le référentiel du noeud présent,
     *  i.e. au niveau des node.children.
     * (Si node == nil -> retourne absPos tel quel,
     * cas où node est aNode.parent et parent peut être nul.)*/
    func inReferentialOf(_ node: Node?) -> Vector2 {
        guard let node = node else { return self }
        let sq = Squirrel(at: node, scaleInit: .scales)
        while sq.goUpPS() {}
        // Maintenant, sq contient la position absolue de theNode.
        return inReferentialOf(sq)
//      if(asDelta) ->  return sq.getRelDeltaOf(self)  // Jamais eu besoin... ?
    }
}

/*
// Structure de base d'un noeud. Contient les liens entre frères, parent, enfants...
// Superflu a priori... ???
class NodeBase: Copyable, Flagable {
    // L'état du noeud, i.e. ensemble de flags binaire. Voir Flag1 pour les flags standards.
    final var flags: Int
    // Id du noeud. (un id par noeud en commençant par 0.)
    final let id: Int
    
    // Liens
    final var firstChild: NodeBase? = nil // Seul firstChild et littleBro sont "strong" pour l'ARC...
    final var littleBro: NodeBase? = nil
    final weak var parent: NodeBase? = nil
    final weak var lastChild: NodeBase? = nil
    final weak var bigBro: NodeBase? = nil
    
    /*-- Init --*/
    init(flags: Int) {
        id = NodeBase.nodeCounter
        NodeBase.nodeCounter &+= 1
        self.flags = flags
    }
    required init(other: NodeBase) {
        id = NodeBase.nodeCounter
        NodeBase.nodeCounter &+= 1
        self.flags = other.flags
    }
    
    /*-----------------------------*/
    /*-- Connect / disconnect / move ---*/
    /** Se retire de sa chaine de frère et met les optionals à nil.
     *  Sera effacé par l'ARC, si n'est pas référencié(swift) ou ramassé par le GC?(Kotlin) */
    final func disconnect() {
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
        // (superflu a priori, mais peux éviter des bogue de double déconnexion si oublie de weak par exemple...)
        parent = nil
        littleBro = nil
        bigBro = nil
    }
    /** Deconnexion d'un descendant, i.e. Effacement direct.
     *  Retourne "true" s'il y a un descendant a effacer. */
    @discardableResult final func disconnectChild(elder: Bool) -> Bool {
        guard let child = elder ? firstChild : lastChild else {
            return false
        }
        child.disconnect()
        return true
    }
    /// Deconnexion d'un frère, i.e. Effacement direct.
    /// Retourne "true" s'il y a un frère a effacer.
    @discardableResult final func disconnectBro(big: Bool) -> Bool {
        guard let bro = big ? bigBro : littleBro else {return false}
        bro.disconnect()
        return true
    }
    /** Connect au parent. (Doit être fullyDeconnect -> optionals à nil.) */
    final func connectToParent(_ parent: NodeBase, asElder: Bool) {
        // Dans tout les cas, on a le parent:
        self.parent = parent
        
        guard let oldParentFirstChild = parent.firstChild,
            let oldParentLastChild = parent.lastChild
        else {
            // Cas parent pas d'enfants
            parent.firstChild = self
            parent.lastChild = self
            return
        }
        // Ajout au début
        if asElder {
            // Insertion
            self.littleBro = oldParentFirstChild
            // Branchement
            oldParentFirstChild.bigBro = self
            parent.firstChild = self
        } else { // Ajout à la fin de la chaine
            // Insertion
            self.bigBro = oldParentLastChild
            // Branchement
            oldParentLastChild.littleBro = self
            parent.lastChild = self
        }
    }
    final func connectToBro(_ bro: NodeBase, asBigbro: Bool) {
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
    
    /** Change un frère de place dans sa liste de frère. */
    final func moveWithinBrosTo(bro: NodeBase, asBigBro: Bool) {
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
    final func moveAsElderOrCadet(asElder: Bool) {
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
    
    /** Change de noeud de place (sans ajuster sa position relative). */
    final func simpleMoveToBro(_ bro: NodeBase, asBigBro: Bool) {
        disconnect()
        connectToBro(bro, asBigbro: asBigBro)
    }
    /** Change de noeud de place (sans ajuster sa position relative). */
    final func simpleMoveToParent(_ newParent: NodeBase, asElder: Bool) {
        disconnect()
        connectToParent(newParent, asElder: asElder)
    }
    
    /*-- Static --*/
    private static var nodeCounter: Int = 0
}

*/
