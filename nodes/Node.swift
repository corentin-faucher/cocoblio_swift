//
//  coqNode.swift
//  
//
//  Created by Corentin Faucher on 2018-10-22.
//
import simd

func printerror(_ message: String, function: String = #function, file: String = #file) {
    print("Error: \(message) in \(function) of file \(file)")
}

protocol CopyableNode {
    init(refNode: Node?, toCloneNode: Self,
         asParent: Bool, asElderBigbro: Bool)
}

extension CopyableNode {
    func copy(refNode: Node?, asParent: Bool = true, asElderBigbro: Bool = false) -> Self {
        return Self.init(refNode: refNode, toCloneNode: self,
                         asParent: asParent, asElderBigbro: asElderBigbro)
    }
}

class Node : CopyableNode {
    /*-- Données de bases --*/
    /** Flags : Les options sur le noeud. */
    private var flags: Int
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
    /** Positions, tailles, etc. */
    var x, y, z, width, height, scaleX, scaleY: SmPos
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
    
    /*-- Fonctions d'accès et Computed properties --*/
    /// Obtenir la position absolue d'un noeud.
    func getAbsPos() -> float2 {
        let sq = Squirrel(at: self)
        while sq.goUpP() {}
        return sq.v
    }
    /** relativePosOf: La position obtenue est dans le référentiel du noeud présent,
     *  i.e. au niveau des node.children.
     * (Si node == nil -> retourne absPos tel quel,
     * cas où node est aNode.parent et parent peut être nul.)*/
    func relativePosOf(absPos: float2) -> float2 {
        let sq = Squirrel(at: self, scaleInit: .scales)
        while sq.goUpPS() {}
        // Maintenant, sq contient la position absolue de theNode.
        return sq.getRelPosOf(absPos)
    }
    func relativeDeltaOf(absDelta: float2) -> float2 {
        let sq = Squirrel(at: self, scaleInit: .scales)
        while sq.goUpPS() {}
        return sq.getRelDeltaOf(absDelta)
    }
    /*-- Constructeurs... */
    /** Noeud "vide" et "seul" */
    init(parent: Node?) {
        flags = 0
        x = SmPos(0)
        y = SmPos(0)
        z = SmPos(0)
        width = SmPos(4)
        height = SmPos(4)
        scaleX = SmPos(1)
        scaleY = SmPos(1)
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
        self.x = SmPos(x, lambda)
        self.y = SmPos(y, lambda)
        self.z = SmPos(0, lambda)
        self.width = SmPos(width, lambda)
        self.height = SmPos(height, lambda)
        scaleX = SmPos(1, lambda)
        scaleY = SmPos(1, lambda)
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
    required internal init(refNode: Node?, toCloneNode: Node,
         asParent: Bool = true, asElderBigbro: Bool = false) {
        // 1. Données de base (SmPos et PerInst. sont des struct)
        self.flags = toCloneNode.flags
        self.x = toCloneNode.x
        self.y = toCloneNode.y
        self.z = toCloneNode.z
        self.width = toCloneNode.width
        self.height = toCloneNode.height
        self.scaleX = toCloneNode.scaleX
        self.scaleY = toCloneNode.scaleY
        piu = toCloneNode.piu
    
        // 2. Ajustement des références
        if let theRef = refNode {
            if (asParent) {
                connectToParent(theRef, asElder: asElderBigbro)
            } else {
                connectToBro(theRef, asBigbro: asElderBigbro)
            }
        }
    }
    
    /*-----------------------------*/
    /*-- Effacement (decconect) ---*/
    /** Se retire de sa chaine de frère et met les optionals à nil.
     *  Sera effacé par l'ARC, si n'est pas référencié(swift) ou ramassé par le GC?(Kotlin) */
    func disconnect() {
        // 1. Retrait
        if bigBro != nil {
            bigBro!.littleBro = littleBro
        } else { // Pas de grand frère -> probablement l'ainé.
            parent?.firstChild = littleBro
        }
        if littleBro != nil {
            littleBro!.bigBro = bigBro
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
    @discardableResult func deconnectChild(elder: Bool) -> Bool {
        guard let child = elder ? firstChild : lastChild else {
            return false
        }
        child.disconnect()
        return true
    }
    /// Deconnexion d'un frère, i.e. Effacement direct.
    /// Retourne "true" s'il y a un frère a effacer.
    @discardableResult func deconnectBro(big: Bool) -> Bool {
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
}

/*---------------------------------------*/
/*-- Les interfaces / protocoles. -------*/
/*---------------------------------------*/

protocol KeyboardKey {
    var scancode: Int { get }
    var keycode: Int { get }
    var keymode: Int { get }
    var isVirtual: Bool { get }
}

protocol DraggableNode {
    func grab(posInit: float2) -> Bool
    func drag(posNow: float2) -> Bool
    func letGo(speed: float2) -> Bool
}

protocol OpenableNode {
    func open()
}

protocol ActionableNode {
    func action()
}

/*---------------------------------------*/
/*-- Les sous-classes importantes. ------*/
/*---------------------------------------*/

class ScreenBase : Node, OpenableNode {
    let escapeAction: (()->Void)?
    let enterAction: (()->Void)?
    
    init(_ refNode: Node?, flags: Int = 0) {
        super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: flags)
    }
    func open() {
        reshape(isOpening: true)
    }
    func reshape(isOpening: Bool) {
        if !containsAFlag(Flag1.dontAlignScreenElements) {
            let ceiledScreenRatio = Renderer.frameUsableWidth / Renderer.frameUsableHeight
            var alignOpt = AlignOpt.respectRatio | AlignOpt.dontSetAsDef
            if (ceiledScreenRatio < 1) {
                alignOpt |= AlignOpt.vertically
            }
            if (isOpening) {
                alignOpt |= AlignOpt.fixPos
            }
            
            self.alignTheChildren(alignOpt: alignOpt, ratio: ceiledScreenRatio)
            
            let scale = min(Renderer.frameUsableWidth / width.realPos,
                            Renderer.frameUsableHeight / height.realPos)
            scaleX.setPos(scale, isOpening)
            scaleY.setPos(scale, isOpening)
        } else {
            scaleX.setPos(1, isOpening)
            scaleY.setPos(1, isOpening)
            width.setPos(Renderer.frameUsableWidth, isOpening)
            height.setPos(Renderer.frameUsableHeight, isOpening)
        }
    }
    
    required internal init(refNode: Node?, toCloneNode: Node,
                           asParent: Bool = true, asElderBigbro: Bool = false) {
        let toCloneScreen = toCloneNode as! ScreenBase
        self.escapeAction = toCloneScreen.escapeAction
        self.enterAction = toCloneScreen.enterAction
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
}


final class Button : Node {
    var bi: ButtonInfo
    init(refNode: Node?, bi: ButtonInfo,
         _ x: Float, _ y: Float, _ height: Float, lambda: Float = 0,
         flags: Int = 0, asParent: Bool = true, asElderBigbro: Bool = false) {
        self.bi = bi
        super.init(refNode, x, y, height, height, lambda: lambda, flags: flags,
                   asParent: asParent, asElderBigbro: asElderBigbro)
        addFlags(Flag1.selectable)
        addRootFlag(Flag1.selectableRoot)
    }
    
    /** Constructeur de copie. */
    required internal init(refNode: Node?, toCloneNode: Node,
         asParent: Bool = true, asElderBigbro: Bool = false) {
        self.bi = (toCloneNode as! Button).bi
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
        addFlags(Flag1.selectable)
        addRootFlag(Flag1.selectableRoot)
    }
}


/** Les flags "de base" pour les noeuds. */
enum Flag1 {
    static let show = 1
    static let hidden = 1<<1
    static let exposed = 1<<2
    static let selectableRoot = 1<<3
    static let selectable = 1<<4
    /** Noeud qui apparaît en grossisant. */
    static let poping = 1<<5
    
    /*-- Pour les surfaces --*/
    /** La tile est l'id de la langue actuelle. */
    //static let languageSurface = 1<<6
    /** Par défaut on ajuste la largeur pour respecter les proportion d'une image. */
    static let surfaceDontRespectRatio = 1<<7
    static let surfaceWithCeiledWidth = 1<<6
    /** String dont il faut vérifier le contenu et le ratio
     *  (fonction de la langue ou éditable). */
//    static let mutableStringSurface = 1<<8
    /** Ajustement du ratio width/height d'un parent en fonction d'un enfant.
     * Par exemple, bouton qui prend les proportions du frame après sa mise à jour. */
//    static let getChildSurfaceRatio = 1<<9
    
    static let giveSizesToBigBroFrame = 1<<8
    static let giveSizesToParent = 1<<9
    
    /*-- Pour les screens --*/
    static let dontAlignScreenElements = 1<<10
    
    /** Paur l'affichage. La branche a encore des descendant à afficher. */
    static let branchToDisplay = 1<<11
    
    /** Le premier flag pouvant être utilisé dans un projet spécifique. */
    static let firstCustomFlag = 1<<12
}
