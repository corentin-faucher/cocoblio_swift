//
//  Root.swift
//  MasaKiokuGameOSX
//
//  Created by Corentin Faucher on 2020-02-07.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation
import simd
import CoreGraphics
#if os(OSX)
import AppKit
#endif

/** Le noeud racine contrôle la caméra.
 	 En effet sa matrice "model" est une matrice "lookAt"
	 étant la première transformation pour tout les objets.
 	 Les positions (x,y,z) sont la position de la caméra.
 	 Par défaut on regarde vers l'origine (0,0,0). */
class RootNode : Node, Reshapable {
    private let up: Vector3 = [0, 1, 0]
    var yLookAt = SmoothPos(0, 5)
    let renderer: Renderer
    
    /// Déplacement relatif de la vue dans son cadre (voir fullHeight vs usableHeight).
    /// Les valeurs acceptable sont entre [-1, 1]. -1: collé en bas, +1: collé en haut.
    let yRelativeDisplacement = SmoothPos(0, 8)
    
    init(refNode: Node? = nil, renderer: Renderer) {
        self.renderer = renderer
        super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: Flag1.exposed|Flag1.show|Flag1.branchToDisplay|Flag1.selectableRoot)
        z.set(4)
    }
    required init(other: Node) {
        renderer = (other as! RootNode).renderer
        super.init(other: other)
    }
    func setModelAsCamera() {
        let yShift = Float(renderer.fullFrame.height - renderer.usableFrame.height) * yRelativeDisplacement.pos / 2
        piu.model.setToLookAt(eye: [x.pos, y.pos + yShift, z.pos], center: [0, yLookAt.pos + yShift, 0], up: up)
    }
    func setProjectionMatrix(_ projection: inout float4x4) {
        projection.setToPerspective(nearZ: 0.1, farZ: 50, middleZ: z.pos,
                                    deltaX: Float(renderer.fullFrame.width),
                                    deltaY: Float(renderer.fullFrame.height))
    }
    func reshape() -> Bool {
        width.set(Float(renderer.usableFrame.width))
        height.set(Float(renderer.usableFrame.height))
        return true
    }
}

class AppRootNode : RootNode {
	private(set) var activeScreen: ScreenBase? = nil
	var selectedNode: Node? = nil
	
	init(renderer: Renderer) {
		super.init(renderer: renderer)
	}
	required init(other: Node) {
		fatalError("init(other:) has not been implemented")
	}
	final func changeActiveScreen(newScreen: ScreenBase?) {
		// 0. Cas réouverture
		if activeScreen === newScreen {
			//newScreen?.closeBranch()
			newScreen?.openBranch()
			return
		}
		// 1. Fermer l'écran actif (déconnecter si evanescent)
		if let lastScreen = activeScreen {
			lastScreen.closeBranch()
			if !lastScreen.containsAFlag(Flag1.persistentScreen) {
				Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
					lastScreen.disconnect()
				}
			}
		}
		// 2. Si null -> fermeture de l'app.
		guard let theNewScreen = newScreen else {
			#if os(OSX)
			activeScreen = nil
			Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { (_) in
				NSApplication.shared.terminate(self)
			}
			#else
			printerror("nil redirect in iOS")
			#endif
			return
		}
		// 3. Ouverture du nouvel écran.
		activeScreen = theNewScreen
		theNewScreen.openBranch()
	}
}
