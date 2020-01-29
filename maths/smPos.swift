//
//  smPos.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2018-11-06.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Darwin



struct SmPos {
    /// Vrai position (dernière entrée). Le setter FIXE la position.
    var realPos: Float {
        get {
            return lastPos
        }
        set(newPos) {
            lastPos = newPos
            A = 0; B = 0
        }
    }
    
    /// Position par défaut (mémoire).
    var defPos: Float
    
    /// Position estimée au temps présent. Setter met à jour la "real" pos. et crée une nouvelle estimation.
    var pos: Float {
        get{
            let deltaT = elapsedSec
            switch type {
            case .oscAmorti:
                return expf(-lambda * deltaT) * (A * cosf(beta * deltaT) + B * sinf(beta * deltaT)) + lastPos
            case .amortiCrit:
                return (A + B * deltaT) * expf(-lambda * deltaT) + lastPos
            case .surAmorti:
                return A * expf(-lambda * deltaT) + B * expf(-beta * deltaT) + lastPos
            case .static_:
                return lastPos
            }
        }
        set(newPos){
            evalAB(with: newPos)
            lastPos = newPos
            setTime = GlobalChrono.elapsedMS32
        }
    }
    
    /// Vitesse estimée au temps présent.
    var vit: Float {
        let deltaT = elapsedSec
        switch type {
        case .oscAmorti:
            return expf(-lambda * deltaT) * ( cosf(beta * deltaT) * (beta*B - lambda*A)
                - sinf(beta * deltaT) * (lambda*B + beta*A) )
        case .amortiCrit:
            return expf(-lambda * deltaT) * (B*(1 - lambda*deltaT) - lambda*A)
        case .surAmorti:
            return -lambda * A * expf(-lambda * deltaT) - beta * B * expf(-beta * deltaT)
        case .static_:
            return 0
        }
    }
    
    
    
    /// Changement de référentiel quelconques (avec positions et scales absolues).
    mutating func newReferential(pos: Float, destPos: Float,
                                 posScale: Float, destScale: Float) {
        lastPos = (pos - destPos) / destScale
        A = A * posScale / destScale
        B = B * posScale / destScale
    }
    mutating func newReferentialAsDelta(posScale: Float, destScale: Float) {
        lastPos = lastPos * posScale / destScale
        A = A * posScale / destScale
        B = B * posScale / destScale
    }
    /// Simple changement de référentiel vers le haut.
    /// Se place dans le référentiel du grand-parent.
    mutating func referentialUp(oldParentPos: Float, oldParentScaling: Float) {
        lastPos = lastPos * oldParentScaling + oldParentPos
        A *= oldParentScaling
        B *= oldParentScaling
    }
    mutating func referentialUpAsDelta(oldParentScaling: Float) {
        lastPos *= oldParentScaling
        A *= oldParentScaling
        B *= oldParentScaling
    }
    /// Simple changement de référentiel vers le bas.
    /// Se place dans le reférentiel d'un frère qui devient parent.
    mutating func referentialDown(newParentPos: Float, newParentScaling: Float) {
        lastPos = (lastPos - newParentPos) / newParentScaling
        A /= newParentScaling
        B /= newParentScaling
    }
    mutating func referentialDownAsDelta(newParentScaling: Float) {
        lastPos /= newParentScaling
        A /= newParentScaling
        B /= newParentScaling
    }
    /// Se place à defPos (smooth).
    mutating func setToDef() {
        pos = defPos
    }
    /** Set avec options : fixer ou non, setter la position par défaut ou non. */
    mutating func setPos(_ newPos: Float, _ fix: Bool = true, _ setDef: Bool = true) {
        if (setDef) {
            defPos = newPos
        }
        if (fix) {
            realPos = newPos
        } else {
            pos = newPos
        }
    }
    /// Se place à defPos + dec.
    mutating func setRelToDef(dec: Float) {
        pos = defPos + dec
    }
    /// Se place à defPos + dec avec effet en arrivant par la "droite".
    mutating func fadeIn(delta: Float, dec: Float) {
        realPos = defPos + dec + delta
        pos = defPos + dec
    }
    /// Tasse l'objet en dehors...
    mutating func fadeOut(delta: Float) {
        pos = lastPos - delta
    }
    
    init(_ posInit: Float, _ lambda: Float) {
        self.init(posInit)
        
        setConstants(gamma: 2*lambda, k: lambda*lambda)
    }
    init(_ posInit: Float) {
        lastPos = posInit
        defPos = posInit
        setTime = GlobalChrono.elapsedMS32
        A = 0; B = 0; self.lambda = 0; beta = 0
        type = .static_
    }
    
    
    // Private Stuff...
    private enum SmPosType {
        case static_
        case oscAmorti
        case amortiCrit
        case surAmorti
    }
    private mutating func setConstants(gamma: Float, k: Float) {
        if gamma == 0 && k == 0 {
            type = .static_
            lambda = 0; beta = 0
            return
        }
        
        let discr = gamma * gamma - 4 * k
        
        if discr > 0.001 {
            type = .surAmorti
            lambda = gamma + discr.squareRoot() / 2
            beta = gamma - discr.squareRoot() / 2
            return
        }
        
        if discr < -0.001 {
            type = .oscAmorti
            lambda = gamma / 2
            beta = sqrtf(-discr)
            return
        }
        
        type = .amortiCrit
        lambda = gamma / 2
        beta = gamma / 2
    }
    private mutating func evalAB(with newPos: Float) {
        let deltaX = pos - newPos
        let Xp = vit
        switch type {
        case .oscAmorti:
            A = deltaX
            B = (Xp + lambda * A) / beta
        case .amortiCrit:
            A = deltaX
            B = Xp + lambda * A
        case .surAmorti:
            A = (beta * deltaX + Xp) / (beta - lambda)
            B = deltaX - A
        case .static_:
            A = 0; B = 0
        }
    }
    
    private var elapsedSec: Float {
        return Float(GlobalChrono.elapsedMS32 &- setTime) * 0.001
    }
    /// Dernière position entrée (realPos...)
    private var lastPos: Float
    private var setTime: UInt32 // 16 pas assez...
    private var A,B,lambda,beta: Float
    private var type: SmPosType
}
