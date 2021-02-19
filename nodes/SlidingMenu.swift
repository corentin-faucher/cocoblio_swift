//
//  SlidingMenu.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

protocol Scrollable : Node {
    /** Scrolling with wheel. */
    func scroll(up: Bool)
    /** Scrolling with trackpad. */
    func trackpadScrollBegan()
    func trackpadScroll(deltaY: Float)
    func trackpadScrollEnded()
}

/** Menu déroulant: root->menu->(item1, item2,... )
* Vide au départ, doit être rempli quand on veut l'afficher.
* if(spacing < 1) -> Recouvrement, if(spacing > 1) -> espacement.
* addNewItem : Typiquement un constructeur de noeud-bouton.
* checkItem : Methode/ext de noeud pour mettre à jour les noeud-boutons.
* getIndicesRangeAtOpening : exécuter à l'ouverture du sliding menu et retourne le range attendu des items.
* getPosIndex : la position de l'indice où on est centré à l'ouverture. */
class SlidingMenu : Node, Scrollable { // Openable
	private unowned let metalView: CoqMetalView
	private let nDisplayed: Int
    private let spacing: Float
	private let addNewItem: ((_ menu: Node, _ index: Int) -> Node)
    private let getIndicesRangeAtOpening: (() -> ClosedRange<Int>?)
    private let getPosIndex: (() -> Int)
    private var menuGrabPosY: Float? = nil
	private var indicesRange: ClosedRange<Int>? = nil
    private var menu: Node! // Le menu qui "glisse" sur le noeud racine.
	private var scrollBar: SlidingMenuScrollBar!
    private var vitY = SmoothPos(0, 4) // La vitesse lors du "fling"
	private var vitYm1: Float = 0
    private var deltaT = Chrono() // Pour la distance parcourue
    private var flingChrono = Chrono() // Temps de "vol"
    
    private var itemHeight: Float {
        return height.realPos / Float(nDisplayed)
    }
    @discardableResult
	init(_ refNode: Node, nDisplayed: Int, metalView: CoqMetalView,
        _ x: Float, _ y: Float, width: Float, height: Float,
        spacing: Float,
        addNewItem: @escaping ((_ menu: Node, _ index: Int) -> Node),
        getIndicesRangeAtOpening: @escaping (() -> ClosedRange<Int>?),
        getPosIndex: @escaping (() -> Int),
        flags: Int=0
    ) {
		self.metalView = metalView
        self.nDisplayed = nDisplayed
        self.spacing = spacing
        self.addNewItem = addNewItem
        self.getIndicesRangeAtOpening = getIndicesRangeAtOpening
        self.getPosIndex = getPosIndex
        
        super.init(refNode,
                   x, y, width, height, lambda: 10, flags: flags)
        makeSelectable()
		let scrollBarWidth = width * 0.025
		menu = Node(self, -scrollBarWidth / 2, 0, width - scrollBarWidth, height, lambda: 20)
		
		scrollBar = SlidingMenuScrollBar(parent: self, width: scrollBarWidth)
		
        tryToAddFrame()
    }
    required init(other: Node)
	{
        let toCloneMenu = other as! SlidingMenu
		metalView = toCloneMenu.metalView
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
    
	
	/** OffsetRatio = */
	func setOffsetRatio(_ offsetRatio: Float, letGo: Bool) {
		let DeltaY = getMenuDeltaYMax()
		let newy = menu.height.realPos * offsetRatio - DeltaY
		if letGo {
			setMenuYpos(yCandIn: newy, snap: true, fix: false)
		} else {
			menu.y.set(newy, true)
		}
		scrollBar.setNubRelY(menu.y.realPos / DeltaY)
		checkItemsVisibility(openNode: true)
	}
	func getOffSetRatio() -> Float {
		return (menu.y.realPos + getMenuDeltaYMax()) / menu.height.realPos
	}
	/** Retourne menu.height / slidmenu.height. Typiquement > 1 (pas besoine de sliding menu si < 1) */
	func getContentFactor() -> Float {
		return menu.height.realPos / height.realPos
	}
	
	/*-- Scrollable (pour macOS et iPadOS avec trackpad/souris)     --*/
	/*!! Pour aller vers le bas du menu -> scrollDeltaY < 0,        !!
	  !! il faut envoyer le menu vers le haut -> menuDeltaY > 0 ... !!*/
	func scroll(up: Bool) {
		setMenuYpos(yCandIn: menu.y.realPos + (up ? -itemHeight : itemHeight), snap: true, fix: false)
		checkItemsVisibility(openNode: true)
	}
	func trackpadScrollBegan() {
		flingChrono.stop()
		vitYm1 = 0
		vitY.set(0)
		deltaT.start()
	}
	func trackpadScroll(deltaY: Float) {
		let menuDeltaY = -0.015 * Float(deltaY)
		setMenuYpos(yCandIn: menu.y.realPos + menuDeltaY, snap: false, fix: false)
		checkItemsVisibility(openNode: true)
		if deltaT.elsapsedSec > 0 {
			vitYm1 = vitY.realPos
			vitY.set(menuDeltaY / deltaT.elsapsedSec)
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
	
	/*-- Openable/Closeable --*/
    override func open() {
        func placeToOpenPos() {
			let first = indicesRange?.first ?? 0
//			let last = indicesRange?.last ?? 0
//			let countMinusOne = last - first
			
			let normalizedId: Int
			let indexAPriori = getPosIndex()
			if let range = indicesRange, range.contains(indexAPriori) {
				normalizedId = indexAPriori - first
			} else {
				normalizedId = 0
			}
			
			let y0 = itemHeight * Float(normalizedId) - getMenuDeltaYMax()
//			let y0 = itemHeight * Float(normalizedId) - 0.5 * itemHeight * Float(countMinusOne)
            setMenuYpos(yCandIn: y0, snap: true, fix: true)
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
		// et vérifier la taille du nub.
		if let range = indicesRange {
			let heightRatio = Float(nDisplayed) / max(1, Float(range.count))
			scrollBar.setNubHeightWithRelHeight(heightRatio)
			for i in range {
				_ = addNewItem(menu, i)
			}
		} else {
			scrollBar.setNubHeightWithRelHeight(1)
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
		
		// 5. Signaler sa présence (pour iOS)
		metalView.addScrollingViewIfNeeded(with: self)
    }
	override func close() {
        super.close()
		metalView.removeScrollingView()
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
		let DeltaY = getMenuDeltaYMax()
        let yCand = snap ?
            round((yCandIn - DeltaY)/itemHeight) * itemHeight + DeltaY
            : yCandIn
        menu.y.set(max(min(yCand, DeltaY), -DeltaY), fix, false)
		scrollBar.setNubRelY(menu.y.realPos / DeltaY)
    }
	/** Le déplacement maximal du menu en y. 0 si n <= nD. */
	private func getMenuDeltaYMax() -> Float {
		return 0.5 * itemHeight * Float(max((indicesRange?.count ?? 0) - nDisplayed, 0))
	}
}

fileprivate class SlidingMenuScrollBar : Node {
	private var nub: Node!
	private var nubTop: TiledSurface!
	private var nubMid: TiledSurface!
	private var nubBot: TiledSurface!
	init(parent: SlidingMenu, width: Float) {
		let parWidth = parent.width.realPos
		let parHeight = parent.height.realPos
		
		super.init(parent, parWidth/2 - width/2, 0, width, parHeight)
		
        let backTex = Texture.getPng("scroll_bar_back")
		let frontTex = Texture.getPng("scroll_bar_front")
		
		// Back of scrollBar
		TiledSurface(self, pngTex: backTex, 0, parHeight/2 - width/2, width)
		let midSec = TiledSurface(self, pngTex: backTex, 0, 0, width, i: 1, flags: Flag1.surfaceDontRespectRatio)
		midSec.height.set(parHeight - 2*width)
		TiledSurface(self, pngTex: backTex, 0, -parHeight/2 + width/2, width, i: 2)
		
		// Nub (sliding)
		nub = Node(self, 0, parHeight/4, width, width*3, lambda: 30)
		nubTop = TiledSurface(nub, pngTex: frontTex, 0, width, width)
		nubMid = TiledSurface(nub, pngTex: frontTex, 0, 0, width, i: 1, flags: Flag1.surfaceDontRespectRatio)
		nubBot = TiledSurface(nub, pngTex: frontTex, 0, -width, width, i: 2)
	}
	required init(other: Node) {
		fatalError("init(other:) has not been implemented")
	}
	
	func setNubHeightWithRelHeight(_ newRelHeight: Float) {
		guard newRelHeight < 1, newRelHeight > 0 else {
			addFlags(Flag1.hidden)
			closeBranch()
			return
		}
		removeFlags(Flag1.hidden)
		let w = width.realPos
		let heightTmp = height.realPos * newRelHeight
		
		let heightMid = max(0, heightTmp - 2 * w)
		nub.height.set(heightMid + 2 * w)
		nubTop.y.set((heightMid + w)/2)
		nubBot.y.set(-(heightMid + w)/2)
		nubMid.height.set(heightMid)
	}
	
	func setNubRelY(_ newRelY: Float) {
		let DeltaY = (height.realPos - nub.height.realPos)/2
		nub.y.pos = -newRelY * DeltaY
	}
}

// GARBAGE

/*-- Draggable (pour iOS) obsolete -> Scrollable --*/
/*
func grab(relPosInit: Vector2) {
    flingChrono.stop()
    menuGrabPosY = relPosInit.y - menu.y.realPos
    vitYm1 = 0
    vitY.set(0)
    deltaT.start()
}
func drag(relPos: Vector2) {
    guard let menuGrabPosY = menuGrabPosY else {
        printerror("drag pas init.")
        return
    }
    guard deltaT.elsapsedSec > 0 else { return }
    
    let lastMenuY = menu.y.realPos
    setMenuYpos(yCandIn: relPos.y - menuGrabPosY, snap: false, fix: false)
    let menuDeltaY = menu.y.realPos - lastMenuY
    checkItemsVisibility(openNode: true)
    vitYm1 = vitY.realPos
    vitY.set(menuDeltaY / deltaT.elsapsedSec)
    deltaT.start()
}
func letGo() {
    // 0. Cas stop. Lâche sans bouger. (vitesse négligeable)
    vitY.set((vitY.realPos + vitYm1)/2)
    print("letGo speed \(vitY.realPos)")
    if abs(vitY.realPos) < 6 {
        setMenuYpos(yCandIn: menu.y.realPos, snap: true, fix: false)
        checkItemsVisibility(openNode: true)
        return
    }
    // 1. Cas on laisse en "fling" (checkItemVisibilty s'occupe de mettre à jour la position)
    flingChrono.start()
    deltaT.start()
    
    checkFling()
}
func justTap() {
    printwarning("Unused.")
}
*/

