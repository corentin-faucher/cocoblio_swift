//
//  Root.swift
//  MasaKiokuGameOSX
//
//  Created by Corentin Faucher on 2020-02-07.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

class RootNode : Node, Reshapable {
    var lootAt: Vector3 = [0, 0, 0]
    var up: Vector3 = [0, 1, 0]
    
    init() {
        super.init(nil, 0, 0, 4, 4, lambda: 0, flags: Flag1.exposed|Flag1.show|Flag1.branchToDisplay|Flag1.selectableRoot|Flag1.reshapableRoot)
        z.set(4)
    }
    func setModelAsCamera() {
        piu.model.setToLookAt(eye: [x.pos, y.pos, z.pos], center: lootAt, up: up)
    }
    
    
    func reshape() -> Bool {
        return true
    }
    
    required internal init(refNode: Node?, toCloneNode: Node, asParent: Bool = true, asElderBigbro: Bool = false) {
        super.init(refNode: refNode, toCloneNode: toCloneNode,
                   asParent: asParent, asElderBigbro: asElderBigbro)
    }
}

