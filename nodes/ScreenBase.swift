//
//  ScreenBase.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

class ScreenBase : Node, Reshapable, Openable {
    let escapeAction: (()->Void)?
    let enterAction: (()->Void)?
    
    init(_ refNode: Node,
         escapeAction: (()->Void)?,
         enterAction: (()->Void)?,
         flags: Int = 0) {
        self.escapeAction = escapeAction
        self.enterAction = enterAction
        super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: flags)
    }
    func open() {
        alignScreenElements(isOpening: true)
    }
    func reshape() -> Bool {
        alignScreenElements(isOpening: false)
        return true
    }
    func alignScreenElements(isOpening: Bool) {
        guard let theParent = parent else {printerror("Pas de parent."); return}
        if !containsAFlag(Flag1.dontAlignScreenElements) {
            let ceiledScreenRatio = theParent.width.realPos / theParent.height.realPos
            var alignOpt = AlignOpt.respectRatio | AlignOpt.setSecondaryToDefPos
            if (ceiledScreenRatio < 1) {
                alignOpt |= AlignOpt.vertically
            }
            if (isOpening) {
                alignOpt |= AlignOpt.fixPos
            }
            
            self.alignTheChildren(alignOpt: alignOpt, ratio: ceiledScreenRatio)
            
            let scale = min(theParent.width.realPos / width.realPos,
                            theParent.height.realPos / height.realPos)
            scaleX.set(scale, isOpening)
            scaleY.set(scale, isOpening)
        } else {
            scaleX.set(1, isOpening)
            scaleY.set(1, isOpening)
            width.set(theParent.width.realPos, isOpening)
            height.set(theParent.height.realPos, isOpening)
        }
    }
    
    required internal init(refNode: Node?, toCloneNode: Node,
                           asParent: Bool = true, asElderBigbro: Bool = false) {
        let toCloneScreen = toCloneNode as! ScreenBase
        self.escapeAction = toCloneScreen.escapeAction
        self.enterAction = toCloneScreen.enterAction
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
}

