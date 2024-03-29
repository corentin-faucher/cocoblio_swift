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
    var mass: Float
    var type: ParticleType
    
    unowned let grid: Grid
    unowned var tile: Tile? = nil
    unowned let ref: Node
        
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
        super.init(ref, pngTex: tex, x, y, height)
    }
    
    func update() {
        guard Particle.deltaT > 1 else { return }
        let dT: Float = Float(Particle.deltaT) / 1000
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
    
    static func setDeltaT() {
        let time = RenderingChrono.elapsedMS
        deltaT = time - lastTime
        lastTime = time
    }
    private static var lastTime: Int64 = RenderingChrono.elapsedMS
    private static var deltaT: Int64 = 0
}


class Bonhomme: Particle {
    // Tirer une balle...
    func action(x: Float, y: Float, speed: Float) {
        Balle(self, x, y, speed)
    }
}

class Balle: Particle {
    @discardableResult
    init(_ ref: Bonhomme, _ x: Float, _ y: Float, _ speed: Float) {
        super.init(grid: ref.grid, ref: ref.parent!, tex: Texture.getPng("the_cat"),
                   ref.x.realPos, ref.y.realPos, 0.5*ref.height.realPos, type: .circle, mass: 0.5)
        visc = 0.1
        // Vitesse du bonhomme
        vit = ref.vit
        // Plus vitesse de la balle relative au bonhomme
        let v2 = Vector2(x, y)
        if length(v2) > 0.00001 {
            vit += speed * normalize(v2)
        } else {
            if length(vit) > 0.0001 {
                vit *= speed
            } else {
                vit += speed * Vector2(1, 0)
            }
        }
        
        openAndShowBranch()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] (_) in
            guard let self = self else { return }
            self.disconnect()
        }
    }
    
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
}

