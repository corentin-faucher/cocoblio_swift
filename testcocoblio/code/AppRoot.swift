//
//  AppRoot.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2022-03-30.
//  Copyright © 2022 Corentin Faucher. All rights reserved.
//

import Foundation

class AppRoot: AppRootBase {
    var particle: Particle!
    override init(view: CoqMetalView) {
        super.init(view: view)
        
        Texture.pngNameToTiling.putIfAbsent(key: "tiles_sol", value: (8, 9))
        let tile = Texture.getPng("tiles_sol")
        let cat = Texture.defaultPng
        
        let grid = Grid(ref: self, m: 30, n: 20, height: 2, tileTex: tile)
        particle = Particle(grid: grid, ref: self, tex: cat, 0, 0, 0.2)
        openAndShowBranch()
    }
    
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    override func willDrawFrame() {
        particle.update()
    }
}
