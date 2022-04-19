//
//  Particule.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2021-10-18.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

import Foundation
import simd

enum ParticleType {
    case square
    case circle
}

class Particle: TiledSurface, Hashable {
    var pos: Vector2  // Position (version pour calcul -> à transférer à x,y...)
    var vit: Vector2  // Vitesse
    var acc: Vector2  // Accélération
    var visc: Float   // Viscosité (proportionnel à la vitesse)
    var fric: Float   // Friction (constant direction opposée à la vitesse)
    var setTime: UInt32 // Instant de la dernière mise à jour
    var mass: Float
    var type: ParticleType
    
    unowned let grid: Grid
    unowned var tile: Tile? = nil
    unowned let ref: Node
    
    var elapsedSec: Float {
        return Float(GlobalChrono.elapsedMS32 &- setTime) * 0.001
    }
    
    init(grid: Grid, ref: Node, tex: Texture,
         _ x: Float, _ y: Float, _ height: Float, type: ParticleType = .circle, mass: Float = 1)
    {
        self.grid = grid
        self.ref = ref
        self.type = type
        self.mass = mass
        pos = Vector2(x, y)
        vit = Vector2(0, 0)
        acc = Vector2(0, 0)
        visc = 3
        fric = 1
        setTime = GlobalChrono.elapsedMS32
        super.init(ref, pngTex: tex, 0, 0, height)
    }
    
    func update() {
        let dT = elapsedSec
        guard dT > 0.005 else { return }
        let v = length(vit)
        if v > 0.00001 {
            // Variation de vitesse dû à la friction.
            var dvf = (visc * v + fric) * dT
            let nv = normalize(vit)
            dvf = min(dvf, v)
            vit += acc * 4 * dT - dvf * nv
        } else {
            if length(acc) == 0 {
                vit = Vector2.zero
            } else {
                vit += acc * 4 * dT
            }
        }
        pos += vit * dT
        setTime = GlobalChrono.elapsedMS32
        x.set(pos.x)
        y.set(pos.y)
    }
    
    func colidWith(_ particle: Particle) {
        switch (type, particle.type) {
            case (.circle, .circle):
                break
            case (.square, .square):
                break
            default:
                break
        }
    }
    
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    /*-- Protocol Hashable --*/
    static func == (lhs: Particle, rhs: Particle) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


class Bonhomme: Particle {
    func action() {
        lancer_balle_de_fusil()
    }
}

class Balle: Particle {
    
}

