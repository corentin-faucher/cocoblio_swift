//
//  SlidingMenu.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/** Menu déroulant: root->menu->(item1, item2,... )
* Vide au départ, doit être rempli quand on veut l'afficher.
* if(spacing < 1) -> Recouvrement, if(spacing > 1) -> espacement.
* addNewItem : Typiquement un constructeur de noeud-bouton.
* checkItem : Methode/ext de noeud pour mettre à jour les noeud-boutons.
* getIndicesRangeAtOpening : exécuter à l'ouverture du sliding menu et retourne le range attendu des items.
* getPosIndex : la position de l'indice où on est centré à l'ouverture. */
class SlidingMenu : Node, Draggable, Scrollable, Openable {
	private let nDisplayed: Int
    private let spacing: Float
	private let addNewItem: ((_ menu: Node, _ index: Int) -> Node)
    private let getIndicesRangeAtOpening: (() -> ClosedRange<Int>?)
    private let getPosIndex: (() -> Int)
    private var menuGrabPosY: Float? = nil
	private var indicesRange: ClosedRange<Int>? = nil
    private var menu: Node! // Le menu qui "glisse" sur le noeud racine.
    private var vitY = SmoothPos(0, 4) // La vitesse lors du "fling"
	private var vitYm1: Float = 0
    private var deltaT = Chrono() // Pour la distance parcourue
    private var flingChrono = Chrono() // Temps de "vol"
    /** Le déplacement maximal du menu en y. 0 si n <= nD. */
    private var menuDeltaYMax: Float {
		return 0.5 * itemHeight * Float(max((indicesRange?.count ?? 0) - nDisplayed, 0))
    }
    private var itemHeight: Float {
        return height.realPos / Float(nDisplayed)
    }
    @discardableResult
    init(_ refNode: Node, nDisplayed: Int,
        _ x: Float, _ y: Float, width: Float, height: Float,
        spacing: Float,
        addNewItem: @escaping ((_ menu: Node, _ index: Int) -> Node),
        getIndicesRangeAtOpening: @escaping (() -> ClosedRange<Int>?),
        getPosIndex: @escaping (() -> Int)
    ) {
        self.nDisplayed = nDisplayed
        self.spacing = spacing
        self.addNewItem = addNewItem
        self.getIndicesRangeAtOpening = getIndicesRangeAtOpening
        self.getPosIndex = getPosIndex
        
        super.init(refNode,
                   x, y, width, height, lambda: 10)
        makeSelectable()
        menu = Node(self, 0, 0, width, height, lambda: 20)
        tryToAddFrame()
    }
    required init(other: Node
    ) {
        let toCloneMenu = other as! SlidingMenu
        nDisplayed = toCloneMenu.nDisplayed
        spacing = toCloneMenu.spacing
        addNewItem = toCloneMenu.addNewItem
        getIndicesRangeAtOpening = toCloneMenu.getIndicesRangeAtOpening
        getPosIndex = toCloneMenu.getPosIndex
        super.init(other: other)
        makeSelectable()
        menu = Node(self, 0, 0, width.realPos, height.realPos, lambda: 20)
        tryToAddFrame()
    }
    
	/*-- Draggable --*/
	#warning("utile pour iOS ? menuGrabPosY, drag avec pos...")
	func grab(relPosInit: Vector2) {
		flingChrono.stop()
		menuGrabPosY = relPosInit.y - menu.y.realPos
		deltaT.start()
	}
	func drag(relPos: Vector2) {
		guard let menuGrabPosY = menuGrabPosY else {
			printerror("drag pas init.")
			return
		}
		setMenuYpos(yCandIn: relPos.y - menuGrabPosY, snap: false, fix: false)
		checkItemsVisibility(openNode: true)
	}
	func letGo(speed: Vector2?) {
		// 0. Cas stop. Lâche sans bouger.
		guard let speed = speed else {
			setMenuYpos(yCandIn: menu.y.realPos, snap: true, fix: false)
			checkItemsVisibility(openNode: true)
			return
		}
		// 1. Cas on laisse en "fling" (checkItemVisibilty s'occupe de mettre à jour la position)
		vitY.set(speed.y/2, true, false)
		flingChrono.start()
		deltaT.start()
		
		checkFling()
	}
	func justTap() {
		printwarning("Unused.")
	}
	
	/*-- Scrollable --*/
	
	func scroll(up: Bool) {
		setMenuYpos(yCandIn: menu.y.realPos + (up ? itemHeight : -itemHeight), snap: true, fix: false)
		checkItemsVisibility(openNode: true)
	}
	func trackpadScrollBegan() {
		flingChrono.stop()
		vitYm1 = 0
		vitY.set(0)
		deltaT.start()
	}
	
	func trackpadScroll(deltaY: Float) {
		let deltaY = 0.015 * Float(deltaY)
		setMenuYpos(yCandIn: menu.y.realPos + deltaY, snap: false, fix: false)
		checkItemsVisibility(openNode: true)
		if deltaT.elsapsedSec > 0 {
			vitYm1 = vitY.realPos
			vitY.set(deltaY / deltaT.elsapsedSec)
		}
		deltaT.start()
	}
	
	func trackpadScrollEnded() {
		vitY.set((vitY.realPos + vitYm1)/2)
		if abs(vitY.realPos) < 6 {
			setMenuYpos(yCandIn: menu.y.realPos, snap: true, fix: false)
			return
		}
		flingChrono.start()
		deltaT.start()
		
		checkFling()
	}
	
	/*-- Openable --*/
    
    func open() {
        func placeToOpenPos() {
			let first = indicesRange?.first ?? 0
			let last = indicesRange?.last ?? 0
			let countMinusOne = last - first
			let normalizedId = max(min(getPosIndex(), last), first) - first
			
            setMenuYpos(yCandIn: itemHeight * (Float(normalizedId) - 0.5 * Float(countMinusOne)),
                        snap: true, fix: true)
        }
        // Mettre tout de suite le flag "show".
        if(!menu.containsAFlag(Flag1.hidden)) {
            menu.addFlags(Flag1.show)
        }
        // 0. Cas pas de changements pour le IntRange,
        flingChrono.stop()
        deltaT.stop()
        let newIndicesRange = getIndicesRangeAtOpening()
        if (indicesRange == newIndicesRange) {
            placeToOpenPos()
            checkItemsVisibility(openNode: false)
            return
        }
        // 1. Changement. Reset des noeuds s'il y en a...
        indicesRange = newIndicesRange
        while (menu.firstChild != nil) {
            menu.disconnectChild(elder: true)
        }
        // 2. Ajout des items avec lambda addingItem
		if let range = indicesRange {
			for i in range {
				_ = addNewItem(menu, i)
			}
		}
        // 3. Normaliser les hauteurs pour avoir itemHeight
        let sq = Squirrel(at: menu)
        if (!sq.goDown()) {
            return
        }
        let smallItemHeight = itemHeight / spacing
        repeat {
            // Scaling -> taille attendu / taille actuelle
            let scale = smallItemHeight / sq.pos.height.realPos
            sq.pos.scaleX.set(scale)
            sq.pos.scaleY.set(scale)
        } while (sq.goRight())

        // 4. Aligner les éléments et placer au bon endroit.
        menu.alignTheChildren(alignOpt: AlignOpt.vertically | AlignOpt.fixPos,
                              ratio: 1, spacingRef: spacing)
        placeToOpenPos()
        checkItemsVisibility(openNode: false)
    }
    
    private func checkFling() {
		guard flingChrono.isActive else {return}
        // 1. Mise à jour automatique de la position en y.
        if (flingChrono.elapsedMS64 > 100) {
            vitY.pos = 0 // Ralentissement...
            // OK, on arrête le "fling" après une seconde...
            if (flingChrono.elapsedMS64 > 1000) {
                flingChrono.stop()
                deltaT.stop()
                setMenuYpos(yCandIn: menu.y.realPos, snap: true, fix: false)
				return
            }
        }
        if (deltaT.elapsedMS64 > 30) {
			let deltaY = deltaT.elsapsedSec * vitY.pos
            setMenuYpos(yCandIn: menu.y.realPos + deltaY,
                        snap: false, fix: false)
            deltaT.start()
        }
        // 2. Vérifier la visibilité des éléments.
        checkItemsVisibility(openNode: true)
        // 3. Callback
        if (deltaT.isActive) {
            Timer.scheduledTimer(withTimeInterval: 0.04, repeats: false) {[weak self] _ in
                self?.checkFling()
            }
        }
    }
    private func checkItemsVisibility(openNode: Bool) {
        // 0. Sortir s'il n'y a rien.
        let sq = Squirrel(at: menu)
        if(!sq.goDown() || !menu.containsAFlag(Flag1.show)) {
            flingChrono.stop()
            deltaT.stop()
            return
        }
        // 1. Ajuster la visibilité des items
        let yActual = menu.y.realPos // TODO: Toujours realPos ??
        repeat {
            let toShow = abs(yActual + sq.pos.y.realPos) < 0.5 * height.realPos

            if (toShow && sq.pos.containsAFlag(Flag1.hidden)) {
                sq.pos.removeFlags(Flag1.hidden)
                if(openNode) {
                    sq.pos.openBranch()
                }
            }
            if (!toShow && !sq.pos.containsAFlag(Flag1.hidden)) {
                sq.pos.addFlags(Flag1.hidden)
                if(openNode) {
                    sq.pos.closeBranch()
                }
            }
        } while (sq.goRight())
    }
    private func setMenuYpos(yCandIn: Float, snap: Bool, fix: Bool) {
        // Il faut "snapper" à une position.
        let yCand = snap ?
            round((yCandIn - menuDeltaYMax)/itemHeight) * itemHeight + menuDeltaYMax
            : yCandIn
        menu.y.set(max(min(yCand, menuDeltaYMax), -menuDeltaYMax), fix, false)
    }
}
