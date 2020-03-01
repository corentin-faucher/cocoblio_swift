//
//  GameEngineBase.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2019-03-21.
//  Copyright © 2019 Corentin Faucher. All rights reserved.
//

import simd
import Foundation

protocol EventsHandler {
    func singleTap(pos: Vector2)
    func initTouchDrag()
    func touchDrag(posNow: Vector2)
    func letTouchDrag(vit: Vector2)
    
    func keyDown(key: KeyboardKey)
    func keyUp(key: KeyboardKey)
    
    func configurationChanged()
    func appPaused()
}

class GameEngineBase {
    /* Les trois noeuds clefs d'un projet. */
    let root: RootNode = RootNode()
    private(set) var activeScreen: ScreenBase? = nil
    var selectedNode: Node? = nil
     
    func willDrawFrame(fullWidth: Float, fullHeight: Float) {
        root.fullWidth = fullWidth
        root.fullHeight = fullHeight
    }
    /* Implémentation par défaut lors d'un reshape -> Redimensionner l'écran. */
    func viewReshaped(usableWidth: Float, usableHeight: Float) {
        root.width.set(usableWidth)
        root.height.set(usableHeight)
        root.reshapeBranch()
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
            print("newScreen == null -> exit")
            // TODO
            //Timer(true).schedule(1000) ...
            //exitProcess(0)
        
            return
        }
        // 3. Ouverture du nouvel écran.
        print("Opening")
        activeScreen = theNewScreen
        theNewScreen.openBranch()
    }
}

