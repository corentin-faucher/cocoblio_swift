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
    var openPos: Int = 0            // Position du sliding menu à l'ouverture (premier élement en haut par défaut)
    
	private unowned let metalView: CoqMetalView
	private let displayedCount: Int     // Nombre d'items affichés (sans dérouler), e.g. 4.
    private var totalCount: Int = 0     // Nombre d'items dans le menu, e.g. 10.
    private let spacing: Float      // Espacement -> ~1
    private var menu: Node!         // Le menu qui "glisse" sur le noeud racine.
	private var scrollBar: SlidingMenuScrollBar!
    private var back: Frame!
    private var vitY = SmoothPos(0, 4) // La vitesse lors du "fling"
	private var vitYm1: Float = 0   // vitesse au temps précédent
    private var deltaT = ChronoR()   // Pour la distance parcourue
    private var flingChrono = ChronoR() // Temps de "vol"
    private var itemHeight: Float {
        return height.realPos / Float(displayedCount)
    }
    
    @discardableResult
	init(_ refNode: Node, nDisplayed: Int, metalView: CoqMetalView,
        _ x: Float, _ y: Float, width: Float, height: Float,
        spacing: Float, flags: Int=0)
    {
		self.metalView = metalView
        self.displayedCount = nDisplayed
        self.spacing = spacing
        super.init(refNode,
                   x, y, width, height, lambda: 10,
                   flags: flags | Flag1.selectableRoot)
        makeSelectable()
        
		let scrollBarWidth = max(width, height) * 0.025
        back = Frame(self, framing: .inside, delta: scrollBarWidth,
                     texture: Texture.getPng("sliding_menu_back"),
                     flags: Flag1.frameOfParent)
        menu = Node(self, -scrollBarWidth / 2, 0, width - scrollBarWidth, height,
                    lambda: 20, flags: Flag1.selectableRoot)
        menu.tryToAddFrame()
		scrollBar = SlidingMenuScrollBar(parent: self, width: scrollBarWidth)
        tryToAddFrame()
    }
    required init(other: Node)
	{
        let toCloneMenu = other as! SlidingMenu
		metalView = toCloneMenu.metalView
        displayedCount = toCloneMenu.displayedCount
        spacing = toCloneMenu.spacing
        super.init(other: other)
        makeSelectable()
        
        menu = Node(self, 0, 0, width.realPos, height.realPos, lambda: 20)
        tryToAddFrame()
    }
    
    func getItemRelativeWidth() -> Float {
        return menu.width.realPos / height.realPos * Float(displayedCount) * spacing
    }
    
    /** Remplissage : Ajout d'un noeud. (Déplace le noeud avec simpleMoveToParent). */
    func addItemInMenu(_ node: Node) {
        node.simpleMoveToParent(menu, asElder: false)        
        totalCount += 1
    }
    func removeAllItemsInMenu() {
        while let child = menu.firstChild {
            child.disconnect()
        }
        totalCount = 0
    }
	
	/** (pour UIScrollView) OffsetRatio : Déroulement des UIScrollView par rapport au haut. */
	func setOffsetRatio(_ offsetRatio: Float, letGo: Bool) {
        guard let DeltaY = getMenuDeltaYMax() else {
            menu.y.set(0, true)
            return
        }
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
        guard let DeltaY = getMenuDeltaYMax() else { return 0 }
		return (menu.y.realPos + DeltaY) / menu.height.realPos
	}
	/** (pour UIScrollView) Retourne menu.height / slidmenu.height. Typiquement > 1 (pas besoine de sliding menu si < 1) */
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
		let menuDeltaY = -0.015 * deltaY
		setMenuYpos(yCandIn: menu.y.realPos + menuDeltaY, snap: false, fix: false)
		checkItemsVisibility(openNode: true)
		if deltaT.elapsedSec > 0 {
			vitYm1 = vitY.realPos
			vitY.set(menuDeltaY / deltaT.elapsedSec)
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
        // Mettre tout de suite le flag "show".
        if(!menu.containsAFlag(Flag1.hidden)) {
            menu.addFlags(Flag1.show)
        }
        flingChrono.stop()
        deltaT.stop()
        // 1. Ajustement de la scroll bar
        if scrollBar.setNubHeightWithRelHeight(Float(displayedCount) / max(1, Float(totalCount))) {
            back.removeFlags(Flag1.hidden)
        } else {
            back.addFlags(Flag1.hidden)
        }
        
        // 3. Normaliser les hauteurs pour avoir itemHeight
        let sq = Squirrel(at: menu)
        guard sq.goDown() else { return }  // (Il faut quelque chose dans le menu.)
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
        // (On remet la largeur à celle du sliding menu, pas la width max des éléments.)
        menu.width.set(menu.width.defPos)
        if let deltaY = getMenuDeltaYMax() {
            setMenuYpos(yCandIn: itemHeight * Float(openPos) - deltaY,
                        snap: true, fix: true)
        } else {
            setMenuYpos(yCandIn: 0, snap: true, fix: true)
        }
        
        checkItemsVisibility(openNode: false)
		
		// 5. Signaler sa présence (pour iOS)
		metalView.addScrollingViewIfNeeded(with: self)
        
        // 6. Open "node" : fadeIn, relativePos...
        super.open()
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
			let deltaY = deltaT.elapsedSec * vitY.pos
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
                    sq.pos.openAndShowBranch()
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
        guard let DeltaY = getMenuDeltaYMax() else {
            menu.y.set(0)
            return
        }
        let yCand = snap ?
            round((yCandIn - DeltaY)/itemHeight) * itemHeight + DeltaY
            : yCandIn
        menu.y.set(max(min(yCand, DeltaY), -DeltaY), fix, false)
        scrollBar.setNubRelY(menu.y.realPos / DeltaY)
    }
	/** Le déplacement maximal du menu en y. nil si n <= nD. */
	private func getMenuDeltaYMax() -> Float? {
        guard totalCount > displayedCount else { return nil }
		return 0.5 * itemHeight * Float(totalCount - displayedCount)
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
	
    // Retourne false si hidden, true si affichy
	func setNubHeightWithRelHeight(_ newRelHeight: Float) -> Bool {
		guard newRelHeight < 1, newRelHeight > 0 else {
			addFlags(Flag1.hidden)
			closeBranch()
			return false
		}
		removeFlags(Flag1.hidden)
		let w = width.realPos
		let heightTmp = height.realPos * newRelHeight
		
		let heightMid = max(0, heightTmp - 2 * w)
		nub.height.set(heightMid + 2 * w)
		nubTop.y.set((heightMid + w)/2)
		nubBot.y.set(-(heightMid + w)/2)
		nubMid.height.set(heightMid)
        return true
	}
	
	func setNubRelY(_ newRelY: Float) {
		let DeltaY = (height.realPos - nub.height.realPos)/2
		nub.y.pos = -newRelY * DeltaY
	}
}


