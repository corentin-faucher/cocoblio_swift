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
typealias Margins = NSEdgeInsets
#else
import UIKit
typealias Margins = UIEdgeInsets
#endif

/** Le noeud racine contrôle la caméra.
 	 En effet sa matrice "model" est une matrice "lookAt"
	 étant la première transformation pour tout les objets. */
class RootNode : Node {
    let camera: Camera
    // Un root node gère le framing de ses descendants
    // width et height sont le "cadre utilisable", i.e. où sont les objets ;
    // et "frame" est le "full frame", i.e. la vue au complet.
    var frame = CGSize(width: 2, height: 2)
    // les marges (en pixels)
    var margins: Margins = Margins(top: 5, left: 5, bottom: 5, right: 5)
    var frameSizeInPx = CGSize(width: 800, height: 600)  // (en pixels)
    var zShift: Float = 0
    private var yShift: CGFloat = 0
    private unowned let parentRoot: RootNode?
    
    /// Déplacement relatif de la vue dans son cadre (voir fullHeight vs usableHeight).
    /// Les valeurs acceptable sont entre [-1, 1]. -1: collé en bas, +1: collé en haut.
    //let yRelativeDisplacement = SmoothPos(0, 8)
    
    init(parent: Node?, parentRoot: RootNode?) {
        if parent != nil {
            if parentRoot == nil {
                printerror("Pas de parent root et n'est pas la root absolue.")
            }
            self.parentRoot = parentRoot
        } else {
            if parentRoot != nil {
                printwarning("Pas besoin de parent root si c'est la root absolue.")
            }
            self.parentRoot = nil
        }
        self.camera = Camera(0, 0, 4)
        super.init(parent, 0, 0, 4, 4, lambda: 5, flags: Flag1.exposed|Flag1.show|Flag1.branchToDisplay|Flag1.selectableRoot|Flag1.isRoot|Flag1.reshapableRoot)
    }
    required init(other: Node) {
        parentRoot = (other as! RootNode).parentRoot
        camera = Camera(0, 0, 4)
        super.init(other: other)
    }
    func setModelMatrix() {
        camera.setAsLookAt(model: &piu.model, yShift: Float(yShift), zShift: zShift)
    }
    func setProjectionMatrix(_ projection: inout float4x4) {
        projection.setToPerspective(nearZ: 0.1, farZ: 50, middleZ: camera.z.pos,
                                    deltaX: Float(frame.width),
                                    deltaY: Float(frame.height))
    }
    func updateFrame(inTransition: Bool = false)
    {
        // 0. Marges...
        let realRatio = frameSizeInPx.width / frameSizeInPx.height
        let ratioT: CGFloat = margins.top / frameSizeInPx.height + 0.01
        let ratioB: CGFloat = margins.bottom / frameSizeInPx.height + 0.01
        let ratioLR: CGFloat = (margins.left + margins.right) / frameSizeInPx.width + 0.015
        // 1. Full Frame
        if realRatio > 1 { // Landscape
            frame.height = 2 / ( 1 - ratioT - ratioB)
            frame.width = realRatio * frame.height
        }
        else {
            frame.width = 2 / (1 - ratioLR)
            frame.height = frame.width / realRatio
        }
        if inTransition {
            return
        }
        // 2. Usable Frame
        if realRatio > 1 { // Landscape
            width.set(Float((1 - ratioLR) * frame.width))
//            width.set(Float(min((1 - ratioLR) * frame.width, 2 * ratioMax)))
            height.set(2)
        }
        else {
            width.set(2)
            height.set(Float((1 - ratioT - ratioB) * frame.height))
//            height.set(Float(min((1 - ratioT - ratioB) * frame.height, 2 / ratioMin)))
        }
        // 3. Shift en y dû aux marge (pour le lookAt)
        yShift = (ratioT - ratioB) * frame.height / 2
        // 4. Reshape de la structure
        reshapeBranch()
    }
    func getNormalizePositionFrom(_ locationInView: CGPoint, invertedY: Bool) -> Vector2 {
        return Vector2(
            Float((locationInView.x / frameSizeInPx.width - 0.5) * frame.width),
            Float((invertedY ? -1 : 1) * (locationInView.y / frameSizeInPx.height - 0.5) * frame.height + yShift)
        )
    }
    func getFrameFrom(_ pos: Vector2, deltas: Vector2) -> CGRect {
        let width: CGFloat = 2 * CGFloat(deltas.x) / frame.width * frameSizeInPx.width
        let height: CGFloat = 2 * CGFloat(deltas.y) / frame.height * frameSizeInPx.height
        #if os(OSX)
        let invertedY = false
        #else
        let invertedY = true
        #endif
        return CGRect(x: (CGFloat(pos.x - deltas.x) / frame.width + 0.5) * frameSizeInPx.width,
                      y: ((CGFloat(pos.y - (invertedY ? -1 : 1) * deltas.y) - yShift) / (frame.height * (invertedY ? -1 : 1)) + 0.5) * frameSizeInPx.height,
                      width: width,
                      height: height)
    }
    override func reshape() {
        guard let parentRoot = parentRoot else { return } // return true }
        frameSizeInPx = parentRoot.frameSizeInPx
        frame = parentRoot.frame
        width.set(parentRoot.width.realPos)
        height.set(parentRoot.height.realPos)
        yShift = parentRoot.yShift
//        return true
    }
}



class AppRootBase : RootNode {
    final unowned let metalView: CoqMetalView
	final private(set) var activeScreen: ScreenBase? = nil
    final private(set) var lastActiveScreenType: ScreenBase.Type? = nil
	final var selectedNode: Node? = nil
	/** Cas particulier de selectedNode. */
	final var grabbedNode: Draggable? = nil
	final var cursor: Cursorable? = nil
	var changeScreenAction: (()->Void)? = nil
	
	
    init(view: CoqMetalView) {
        self.metalView = view
		super.init(parent: nil, parentRoot: nil)
	}
	required init(other: Node) {
		fatalError("init(other:) has not been implemented")
	}
	
	/** Method called every frame by the renderer. To be overwritted. */
	func willDrawFrame() {
        // (pass)
	}
    
    func didResume(after sleepingTimeSec: Float) {
        // (pass)
    }
	
    final func changeActiveScreenTo(_ newScreen: ScreenBase?) {
		// 0. Cas réouverture
		if activeScreen === newScreen {
			newScreen?.openAndShowBranch()
			return
		}
		// 1. Fermer l'écran actif (déconnecter si evanescent)
		closeActiveScreen()
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
        setActiveScreen(theNewScreen)
	}
    
    final func changeActiveScreenToNewType(_ screenType: ScreenBase.Type) {
        // 1. Fermer l'écran actif (déconnecter si evanescent)
        closeActiveScreen()
        // 3. Ouverture du nouvel écran.
        let newScreen = screenType.init(self)
        setActiveScreen(newScreen)
    }
    
    private final func closeActiveScreen() {
        if let lastScreen = activeScreen {
            lastActiveScreenType = type(of: lastScreen)
            lastScreen.closeBranch()
            if !lastScreen.containsAFlag(Flag1.persistentScreen) {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
                    lastScreen.disconnect()
                }
            }
        } else {
            lastActiveScreenType = nil
        }
        activeScreen = nil
    }
    /// À utiliser après closeActiveScreen.
    private final func setActiveScreen(_ newScreen: ScreenBase) {
        activeScreen = newScreen
        newScreen.openAndShowBranch()
        changeScreenAction?.self()
    }
}

/** Une caméra pourrait faire partir de l'arborescence... Mais pour le moment c'est un noeud "à part"...*/
class Camera: Node {
    var x_up, y_up, z_up: SmoothPos
    var x_center, y_center, z_center: SmoothPos
    
    init(_ x: Float, _ y: Float, _ z: Float, lambda: Float = 10) {
        x_up = SmoothPos(0, lambda)
        y_up = SmoothPos(1, lambda)
        z_up = SmoothPos(0, lambda)
        x_center = SmoothPos(0, lambda)
        y_center = SmoothPos(0, lambda)
        z_center = SmoothPos(0, lambda)
        super.init(nil, x, y, z, width: 1, height: 1, lambda: lambda, flags: 0)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    func setAsLookAt(model: inout float4x4, yShift: Float, zShift: Float) {
        // (avec des rotations, ce serait plutôt eye = pos + yShift * up, et center = center + yShift * up...)
        model.setToLookAt(eye: [x.pos, y.pos + yShift, z.pos + zShift],
                          center: [x_center.pos, y_center.pos + yShift, z_center.pos],
                          up: [x_up.pos, y_up.pos, z_up.pos])
    }
}
