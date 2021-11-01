//
//  Particule.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2021-10-18.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

import Foundation

class Particule : Node {
    var pos: Vector2  // Position (version pour calcul -> à transférer à x,y...)
    var vit: Vector2  // Vitesse
    var acc: Vector2  // Accélération
    var r: Float      // Rayon de collision
    var visc: Float   // "Friction" de viscosité (proportionnel à la vitesse)
    var setTime: UInt32 // Instant de la dernière mise à jour
    var elapsedSec: Float {
        return Float(GlobalChrono.elapsedMS32 &- setTime) * 0.001
    }
    init(_ refNode: Node?,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float)
    {
        pos = Vector2(x, y)
        vit = Vector2(0, 0)
        acc = Vector2(0, 0)
        r = max(width, height)
        visc = 0.1
        setTime = GlobalChrono.elapsedMS32
        super.init(refNode, x, y, width, height)
    }
    
    func update() {
        let dT = elapsedSec
        guard dT > 0.005 else { return }
        vit += (acc - visc * vit) * dT
        pos += vit * dT
        x.set(pos.x, true, false)
        y.set(pos.y, true, false)
        setTime = GlobalChrono.elapsedMS32
    }
    
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
}

enum TileType: CaseIterable {
    case mur
    case plancher
    case trou
}

class Tile: TiledSurface {
    var type: TileType = .mur
    
    init(_ parent: Node, tex: Texture, _ x: Float, _ y: Float, _ height: Float)
    {
        super.init(parent, pngTex: tex, x, y, height)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    func updateTile(left: TileType, right: TileType, up: TileType, down: TileType)
    {
        guard type != .plancher else {
            updateTile(Int.random(in: 0..<8), 4)
            return
        }
        let i_base = Bool.random() ? 0 : 4
        let j_base = type == .mur ? 0 : 5
        switch (left, right, up, down) {
            case (type, type, type, type):      // milieu
                updateTile(1 + i_base, 1 + j_base)
            case (type, type, _, type):         // haut
                updateTile(1 + i_base, 0 + j_base)
            case (type, type, type, _):         // bas
                updateTile(1 + i_base, 2 + j_base)
            case (_, type, type, type):         // gauche
                updateTile(0 + i_base, 1 + j_base)
            case (type, _, type, type):         // droite
                updateTile(2 + i_base, 1 + j_base)
            case (_, type, _, type):            // g.-haut
                updateTile(0 + i_base, 0 + j_base)
            case (type, _, _, type):            // dr.-haut
                updateTile(2 + i_base, 0 + j_base)
            case (_, type, type, _):            // g.-bas
                updateTile(0 + i_base, 2 + j_base)
            case (type, _, type, _):            // dr.-bas
                updateTile(2 + i_base, 2 + j_base)
            case (type, type, _, _):            // hor.
                updateTile(1 + i_base, 3 + j_base)
            case (_, _, type, type):            // vert.
                updateTile(3 + i_base, 1 + j_base)
            case (_, type, _, _):               // hor, g.
                updateTile(0 + i_base, 3 + j_base)
            case (type, _, _, _):               // hor, dr.
                updateTile(2 + i_base, 3 + j_base)
            case (_, _, _, type):               // vert., h.
                updateTile(3 + i_base, 0 + j_base)
            case (_, _, type, _):               // vert., b.
                updateTile(3 + i_base, 2 + j_base)
            default:                            // isolé
                updateTile(3 + i_base, 3 + j_base)
        }
    }
}

/** La base d'un niveau avec ses tiles */
class Platforme : Node {
    var tiles: [[Tile]] = []
    
    @discardableResult
    init(_ parent: Node, tex: Texture, n: Int, _ x: Float, _ y: Float, _ height: Float)
    {
        super.init(parent, x, y, height, height)
        // Remplissage
        tiles = Array(repeating: [], count: n)
        let delta = height / Float(n)
        let min = -0.5 * height + 0.5 * delta
        for i in 0..<n {
            let tile_x = min + Float(i) * delta
            for j in 0..<n {
                let tile_y = min + Float(j) * delta
                tiles[i].append(
                    Tile(self, tex: tex, tile_x, tile_y, delta)
                )
            }
        }
        // Choix des tiles.
        var i_0 = 0
        var i_1 = n-1
        var j_0 = 0
        var j_1 = n-1
        var left = Platforme.defType // précédent
        var up = Platforme.defType   // ligne précédente
        while true {
            // gauche (bas->haut)
            for j in j_0...j_1 {
                left = j>0 ? tiles[i_0][j-1].type : Platforme.defType
                up = i_0>0 ? tiles[i_0-1][j].type : Platforme.defType
                tiles[i_0][j].type = Platforme.getTileType(left: left, up: up)
            }
            i_0 += 1 // (gauche fini)
            guard i_0 <= i_1 else { break }
            // haut (gauche->droite)
            for i in i_0...i_1 {
                left = tiles[i-1][j_1].type
                up = j_1<n-1 ? tiles[i][j_1+1].type : Platforme.defType
                tiles[i][j_1].type = Platforme.getTileType(left: left, up: up)
            }
            j_1 -= 1 // (haut fini)
            guard j_0 <= j_1 else { break }
            // droite (haut->bas)
            for j in (j_0...j_1).reversed() {
                left = tiles[i_1][j+1].type
                up = i_1 < n-1 ? tiles[i_1][j].type : Platforme.defType
                tiles[i_1][j].type = Platforme.getTileType(left: left, up: up)
            }
            i_1 -= 1 // (droite fini)
            guard i_0 <= i_1 else { break }
            // bas (droite->gauche)
            for i in (i_0...i_1).reversed() {
                left = tiles[i+1][j_0].type
                up = j_0 > 0 ? tiles[i][j_0-1].type : Platforme.defType
                tiles[i][j_0].type = Platforme.getTileType(left: left, up: up)
            }
            j_0 += 1 // (bas fini)
            guard j_0 <= j_1 else { break }
        }
        // Ajustement avec les voisins
        for i in 0..<n {
            for j in 0..<n {
                let left = tiles[safe: i-1]?[j].type ?? Platforme.defType
                let right = tiles[safe: i+1]?[j].type ?? Platforme.defType
                let up = tiles[i][safe: j+1]?.type ?? Platforme.defType
                let down = tiles[i][safe: j-1]?.type ?? Platforme.defType
                tiles[i][j].updateTile(left: left, right: right, up: up, down: down)
            }
        }
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    private static func getTilePos(_ index: Int, min: Float, delta: Float) -> Float
    {
        return min + Float(index) * delta
    }
    private static let defType = TileType.plancher
    private static func getTileType(left: TileType, up: TileType) -> TileType
    {
        switch Float.random(in: 0...1) {
            case ..<0.35: return left
            case ..<0.70: return up
            case ..<0.82: return .mur
            case ..<0.85: return .trou
            default: return .plancher
        }
    }
    func setAllTiles() {
        
    }
}
