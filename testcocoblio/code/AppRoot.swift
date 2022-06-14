//
//  AppRoot.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2022-03-30.
//  Copyright © 2022 Corentin Faucher. All rights reserved.
//

import Foundation

class AppRoot: AppRootBase {
    var bonhomme: Bonhomme!
    override init(view: CoqMetalView) {
        super.init(view: view)
        
        Texture.pngNameToTiling.putIfAbsent(key: "tiles", value: (3, 3))
        Texture.pngNameToTiling.putIfAbsent(key: "monstres", value: (3, 1))
        let tileTex = Texture.getPng("tiles")
        let monstresTex = Texture.getPng("monstres")
        
        let grid = Grid(ref: self, m: 30, n: 20, height: 2, tileTex: tileTex)
        bonhomme = Bonhomme(grid: grid, ref: self, tex: monstresTex, 0, 0, 0.2)
        bonhomme.updateTile(2, 0)
        openAndShowBranch()
    }
    
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    override func willDrawFrame() {
        Particle.setDeltaT()
        forEachTypedNodeInBranch { (part: Particle) in
            part.update()
        }
    }
}
