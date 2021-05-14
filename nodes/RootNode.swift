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

fileprivate let ratioMin: CGFloat = 0.54
fileprivate let ratioMax: CGFloat = 1.85

/** Le noeud racine contrôle la caméra.
 	 En effet sa matrice "model" est une matrice "lookAt"
	 étant la première transformation pour tout les objets. */
class RootNode : Node {
    let camera: Camera
    // Un root node gère le framing de ses descendants
    // width et height sont le "cadre utilisable", i.e. où sont les objets ;
    // et "frame" est le "full frame", i.e. la vue au complet.
    var frame = CGSize(width: 2, height: 2)
    private var yShift: CGFloat = 0
    private var frameSizeInPx = CGSize(width: 100, height: 100)  // (en pixels)
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
                printwarning("Pas besoin de parent root si ist la root absolue.")
            }
            self.parentRoot = nil
        }
        self.camera = Camera(0, 0, 4)
        super.init(parent, 0, 0, 4, 4, lambda: 5, flags: Flag1.exposed|Flag1.show|Flag1.branchToDisplay|Flag1.selectableRoot|Flag1.isRoot)
    }
    required init(other: Node) {
        parentRoot = (other as! RootNode).parentRoot
        camera = Camera(0, 0, 4)
        super.init(other: other)
    }
    func setModelMatrix() {
        camera.setAsLookAt(model: &piu.model, yShift: Float(yShift))
    }
    func setProjectionMatrix(_ projection: inout float4x4) {
        projection.setToPerspective(nearZ: 0.1, farZ: 50, middleZ: camera.z.pos,
                                    deltaX: Float(frame.width),
                                    deltaY: Float(frame.height))
    }
    func updateFrame(to newSize: CGSize,
                     withMargin top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat,
                     inTransition: Bool = false)
    {
        // 0. Marges...
        frameSizeInPx = newSize
        let realRatio = newSize.width / newSize.height
        let ratioT: CGFloat = top / frameSizeInPx.height + 0.01
        let ratioB: CGFloat = bottom / frameSizeInPx.height + 0.01
        let ratioLR: CGFloat = (left + right) / frameSizeInPx.width + 0.015
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
            width.set(Float(min((1 - ratioLR) * frame.width, 2 * ratioMax)))
            height.set(2)
        }
        else {
            width.set(2)
            height.set(Float(min((1 - ratioT - ratioB) * frame.height, 2 / ratioMin)))
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
    func getFrameFrom(_ pos: Vector2, deltas: Vector2, invertedY: Bool) -> CGRect {
        let width: CGFloat = 2 * CGFloat(deltas.x) / frame.width * frameSizeInPx.width
        let height: CGFloat = 2 * CGFloat(deltas.y) / frame.height * frameSizeInPx.height
        return CGRect(x: (CGFloat(pos.x - deltas.x) / frame.width + 0.5) * frameSizeInPx.width,
                      y: ((CGFloat(pos.y - (invertedY ? -1 : 1) * deltas.y) - yShift) / (frame.height * (invertedY ? -1 : 1)) + 0.5) * frameSizeInPx.height,
                      width: width,
                      height: height)
    }
    override func reshape() -> Bool {
        guard let parentRoot = parentRoot else {
            return true
        }
        frameSizeInPx = parentRoot.frameSizeInPx
        frame = parentRoot.frame
        width.set(parentRoot.width.realPos)
        height.set(parentRoot.height.realPos)
        yShift = parentRoot.yShift
        return true
    }
}



class AppRootBase : RootNode {
	private(set) var activeScreen: ScreenBase? = nil
	var selectedNode: Node? = nil
	/** Cas particulier de selectedNode. */
	var grabbedNode: Draggable? = nil
	var cursor: Cursorable? = nil
	var changeScreenAction: (()->Void)? = nil
	
	
	init() {
		super.init(parent: nil, parentRoot: nil)
	}
	required init(other: Node) {
		fatalError("init(other:) has not been implemented")
	}
	
	/** Method called every frame by the renderer. To be overwritted. */
	func willDrawFrame() {
		printwarning("Plese override willDrawFrame...")
	}
	
	final func changeActiveScreen(newScreen: ScreenBase?) {
		// 0. Cas réouverture
		if activeScreen === newScreen {
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
        super.init(nil, x, y, 1, 1, lambda: lambda)
        self.z.set(z)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    func setAsLookAt(model: inout float4x4, yShift: Float) {
        // (avec des rotations, ce serait plutôt eye = pos + yShift * up, et center = center + yShift * up...)
        model.setToLookAt(eye: [x.pos, y.pos + yShift, z.pos],
                          center: [x_center.pos, y_center.pos + yShift, z_center.pos],
                          up: [x_up.pos, y_up.pos, z_up.pos])
    }
}
