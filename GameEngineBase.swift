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
    func everyFrameAction()
    func initTouchDrag()
    func touchDrag(posNow: float2)
    func letTouchDrag(vit: float2)
    func singleTap(pos: float2)
    func keyDown(key: KeyboardKey)
    func keyUp(key: KeyboardKey)
    func reshapeAction()
}

@objc class GameEngineBase : NSObject {
    /* Les trois noeuds clefs d'un projet. */
    let root: Node = Node(nil, 0, 0, 4, 4, lambda: 0, flags:
        Flag1.exposed|Flag1.show|Flag1.branchToDisplay|Flag1.selectableRoot)
    private(set) var activeScreen: ScreenBase? = nil
    private(set) var selectedNode: Node? = nil
    
    /* Action supplémentaire à l'ouverture/fermeture pour les noeuds. */
    let extraCheckNodeAtOpening: ((Node) -> Void)? = nil
    let extraCheckNodeAtClosing: ((Node) -> Void)? = nil
    
    /* Implémentation par défaut lors d'un reshape -> Redimensionner l'écran. */
    func reshapeAction() {
        activeScreen?.reshape(isOpening: false)
    }
    
    func changeActiveScreen(newScreen: ScreenBase?) {
        // 0. Cas réouverture
        if activeScreen === newScreen {
            newScreen?.closeBranch()
            newScreen?.openBranch()
            return
        }
        // 1. Si besoin, fermer l'écran actif.
        activeScreen?.closeBranch(extraCheck: extraCheckNodeAtClosing)
        
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
        activeScreen = theNewScreen
        theNewScreen.openBranch(extraCheck: extraCheckNodeAtOpening)
    }
}

