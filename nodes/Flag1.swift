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
    /** Noeud qui apparaît en grossisant. */
    static let poping = 1<<5
    
    static let isRoot = 1<<6
    
    /*-- Pour les surfaces --*/
    /** Par défaut on ajuste la largeur pour respecter les proportion d'une image. */
    static let surfaceDontRespectRatio = 1<<7
    static let surfaceWithCeiledWidth = 1<<8
    /*-- Pour les ajustement de height/width du parent ou du frame --*/
    static let giveSizesToBigBroFrame = 1<<9
    static let giveSizesToParent = 1<<10
	
	/*-- Pour les screens --*/
    static let dontAlignScreenElements = 1<<11
	/** Par défaut un screen est evanescent (disconnect apres usage). */
	static let persistentScreen = 1<<12
    
    /** Paur l'affichage. La branche a encore des descendant à afficher. */
    static let branchToDisplay = 1<<13
    
	/*-- Placements à l'ouverture --*/
    static let relativeToRight = 1<<14
    static let relativeToLeft = 1<<15
    static let relativeToTop = 1<<16
    static let relativeToBottom = 1<<17
    static let fadeInRight = 1<<18
    static let relativeFlags = relativeToRight | relativeToLeft | relativeToTop | relativeToBottom
	static let openFlags = relativeToRight | relativeToLeft | relativeToTop | relativeToBottom | fadeInRight
	
    /// Descendant ne devant pas être aligné
	static let notToAlign = 1<<19
    
    static let stringRightJustified = 1<<20
	
    /** Le premier flag pouvant être utilisé dans un projet spécifique. */
    static let firstCustomFlag = 1<<21
}

