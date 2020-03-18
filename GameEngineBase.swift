//
//  GameEngineBase.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2019-03-21.
//  Copyright © 2019 Corentin Faucher. All rights reserved.
//

import simd
import Foundation
#if os(OSX)
import AppKit
#endif

protocol EventsHandler {
    func singleTap(pos: Vector2)
    func initTouchDrag()
    func touchDrag(posNow: Vector2)
    func letTouchDrag(vit: Vector2)
    
    func keyDown(key: KeyboardKey)
    func keyUp(key: KeyboardKey)
    
    func appStart()
    func configurationChanged()
    func appPaused()
    
    func willDrawFrame()
}

class GameEngineBase {
    /* Les trois noeuds clefs d'un projet. */
    var root: RootNode
    private(set) var activeScreen: ScreenBase? = nil
    var selectedNode: Node? = nil
    
    init(renderer: Renderer) {
        root = RootNode(refNode: nil, renderer: renderer)
    }
     
    final func changeActiveScreen(newScreen: ScreenBase?) {
        // 0. Cas réouverture
        if activeScreen === newScreen {
            newScreen?.closeBranch()
            newScreen?.openBranch()
            return
        }
        // 1. Si besoin, fermer l'écran actif.
        activeScreen?.closeBranch()
        
        // 2. Si null -> fermeture de l'app.
        guard let theNewScreen = newScreen else {
            activeScreen = nil
            #if os(OSX)
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { (_) in
                NSApplication.shared.terminate(self)
            }
            #endif
            return
        }
        // 3. Ouverture du nouvel écran.
        activeScreen = theNewScreen
        theNewScreen.openBranch()
    }
}

