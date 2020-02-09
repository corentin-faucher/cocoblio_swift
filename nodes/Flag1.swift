//
//  Flag1.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-31.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation


/** Les flags "de base" pour les noeuds. */
enum Flag1 {
    static let show = 1
    static let hidden = 1<<1
    static let exposed = 1<<2
    static let selectableRoot = 1<<3
    static let selectable = 1<<4
    static let reshapableRoot = 1<<5
    /** Noeud qui apparaît en grossisant. */
    static let poping = 1<<6
    
    /*-- Pour les surfaces --*/
    /** Par défaut on ajuste la largeur pour respecter les proportion d'une image. */
    static let surfaceDontRespectRatio = 1<<7
    static let surfaceWithCeiledWidth = 1<<8
    /*-- Pour les ajustement de height/width du parent ou du frame --*/
    static let giveSizesToBigBroFrame = 1<<8
    static let giveSizesToParent = 1<<10
    
    /*-- Pour les screens --*/
    static let dontAlignScreenElements = 1<<11
    
    /** Paur l'affichage. La branche a encore des descendant à afficher. */
    static let branchToDisplay = 1<<12
    
    /** Le premier flag pouvant être utilisé dans un projet spécifique. */
    static let firstCustomFlag = 1<<13
}

