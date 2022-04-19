//
//  Grid.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2022-03-30.
//  Copyright © 2022 Corentin Faucher. All rights reserved.
//

import Foundation

enum TileType: CaseIterable {
    case mur
    case plancher
    case trou
}

class Tile: TiledSurface {
    let pos: Vector2
    var type: TileType
    
    unowned var up: Tile? = nil
    unowned var down: Tile? = nil
    unowned var right: Tile? = nil
    unowned var left: Tile? = nil
    
    var particles: Set<Particle> = []
    
    init(grid: Grid, pos: Vector2, side: Float, type: TileType, tex: Texture) {
        self.pos = pos
        self.type = type
        let i: Int
        switch type {
            case .mur:
                i = 9
            case .plancher:
                i = 32
            case .trou:
                i = 49
        }
        super.init(grid, pngTex: tex, pos.x, pos.y, side, i: i)
    }
    required init(other: Node) {
        let otherTile = other as! Tile
        pos = otherTile.pos
        type = otherTile.type
        super.init(other: other)
    }
    
    func updateSurface()
    {
        guard type != .plancher else {
            updateTile(Int.random(in: 0..<8), 4)
            return
        }
        let i_base = Bool.random() ? 0 : 4
        let j_base = type == .mur ? 0 : 5
        switch (left?.type ?? .trou, right?.type ?? .trou, up?.type ?? .trou, down?.type ?? .trou) {
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

class Grid: Node {
    var tiles: [Tile] = []
    let side: Float
    // Coordonnées (centrale) de la première tile (en haut à gauche)
    let pos0: Vector2
    let m, n: Int
    
    init(ref: Node, m: Int, n: Int, height: Float, tileTex: Texture) {
        side = height / Float(n)
        pos0 = Vector2(x: -Float(m - 1) * side / 2, y: Float(n - 1) * side / 2)
        self.m = m
        self.n = n
        super.init(ref, 0, 0, height * Float(m) / Float(n), height)
        var left: Tile? = nil
        var up: Tile? = nil
        for i in 0..<m {
            for j in 0..<n {
                // Obtenir les tiles précédentes (en haut et à gauche).
                if j > 0 {
                    up = tiles[j - 1 + i * n]
                } else {
                    up = nil
                }
                if i > 0 {
                    left = tiles[j + (i-1) * n]
                } else {
                    left = nil
                }
                // Choisir un type de tile allant avec les tiles précédentes.
                let newType = Grid.getTileType(left: left?.type ?? .mur, up: up?.type ?? .mur)
                let newPos = getPositionOfTile(i: i, j: j)
                let newTile = Tile(grid: self, pos: newPos, side: side, type: newType, tex: tileTex)
                newTile.left = left
                newTile.up = up
                left?.right = newTile
                up?.down = newTile
                
                tiles.append(newTile)
            }
        }
        for tile in tiles {
            tile.updateSurface()
        }
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    
    
    func checkParticule(_ particle: Particle) {
        // 1. Cas on a déjà une tile...
        if let tile = particle.tile {
            let deltaX = particle.pos.x - tile.pos.x
            let deltaY = particle.pos.y - tile.pos.y
            // Toujour proche de la tile ? (pas de changement)
            if fabsf(deltaX) <= side * 0.55, fabsf(deltaY) <= side * 0.55 {
                return
            }
            var newTile: Tile = tile
            // Aller à droit/gauche/haut/bas ?
            if deltaX > 0.5*side, let r_tile = newTile.right  {
                newTile = r_tile
            }
            if deltaX < -0.5*side, let l_tile = newTile.left {
                newTile = l_tile
            }
            if deltaY > 0.5*side, let u_tile = newTile.up {
                newTile = u_tile
            }
            if deltaY < -0.5*side, let d_tile = newTile.down {
                newTile = d_tile
            }
            // (pas de changement, cas sur les bords)
            guard newTile !== tile else { return }
            // Retrait / ajout
            let rem = tile.particles.remove(particle)
            guard rem != nil else {
                printerror("Cannot remove particle at \(particle.pos).")
                return
            }
            particle.tile = nil
            let ins = newTile.particles.insert(particle)
            guard rem != nil, ins.inserted else {
                printerror("Cannot remove and insert particle at \(particle.pos).")
                return
            }
            particle.tile = newTile
            return
        }
        // 2. Pas de tile attribuée. -> trouver la plus proche.
        let tile = getClosestTileTo(pos: particle.pos)
        let ins = tile.particles.insert(particle)
        guard ins.inserted else {
            printerror("Cannot insert particule at \(particle.pos) to tile at \(tile.pos).")
            return
        }
        particle.tile = tile
    }
    
    private func getClosestTileTo(pos: Vector2) -> Tile {
        let i = min(max(((pos.x - pos0.x) / side).roundToInt(), 0), m-1)
        let j = min(max(((pos.y - pos0.y) / side).roundToInt(), 0), n-1)
        return tiles[i*n + j]
    }
    private func getPositionOfTile(i: Int, j: Int) -> Vector2 {
        return pos0 + Vector2(x: Float(i) * side, y: -Float(j) * side)
    }
    
    /** Génération simple d'une tile en fonction des voisins précédent. */
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
}
