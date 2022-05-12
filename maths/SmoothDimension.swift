//
//  smPos.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2018-11-06.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Darwin

private var defaultFadeDelta: Float = 2.2

protocol SmoothDimension {
    var realPos: Float {get}
    var defPos: Float {get set}
    var pos: Float {get set}
    var speed: Float {get}
    
    init(_ posInit: Float, _ lambda: Float)
    init(_ posInit: Float)
    
    /** Set la position, avec options : fixer ou non, setter la position par défaut ou non. */
    mutating func set(_ newPos: Float, _ fix: Bool, _ setAsDef: Bool)
    /// Se place à defPos + shift. (convenience de set)
    mutating func setRelToDef(shift: Float, fix: Bool)
    /** Se place à realPos + shift. (convenience de set) */
    mutating func move(shift: Float, fix: Bool, setAsDef: Bool)
    /// Se place à defPos avec effet d'arriver de defPos + delta. (convenience de set)
    mutating func fadeIn(delta: Float?)
	/// Se place à defPos + delta avec effet d'arriver de defPos. (convenience de set)
	mutating func fadeInFromDef(delta: Float?)
    /// Se place à realPos - delta. (convenience de set)
    mutating func fadeOut(delta: Float?)
}

/// Default implementation des convenience de set
extension SmoothDimension {
    mutating func setRelToDef(shift: Float, fix: Bool) {
        set(defPos + shift, fix, false)
    }
    mutating func move(shift: Float, fix: Bool, setAsDef: Bool) {
        set(realPos + shift, fix, setAsDef)
    }
    mutating func fadeIn(delta: Float? = nil) {
		set(defPos + (delta ?? defaultFadeDelta), true, false)
        set(defPos, false, false)
    }
	mutating func fadeInFromDef(delta: Float? = nil) {
		set(defPos, true, false)
		set(defPos + (delta ?? defaultFadeDelta), false, false)
	}
    mutating func fadeOut(delta: Float? = nil) {
        set(realPos - (delta ?? defaultFadeDelta), false, false)
    }
}

private enum SmDimType {
    case static_
    case oscAmorti
    case amortiCrit
    case surAmorti
}

private protocol CurveInfo {
    var A: Float {get set}
    var B: Float {get set}
    var lambda: Float {get set}
    var beta: Float {get set}
    var type: SmDimType {get set}
    var setTime: UInt32 {get set}
    var elapsedSec: Float {get}
    
    mutating func updateParameters(gamma: Float, k: Float)
    mutating func setLambdaBetaType(gamma: Float, k: Float)
    mutating func setAB(delta: Float, slope: Float)
    
    func getSlope(deltaT: Float) -> Float
    func getDelta(deltaT: Float) -> Float
}

private extension CurveInfo {
    var elapsedSec: Float {
        return Float(RenderingChrono.elapsedMS32 &- setTime) * 0.001
    }
    mutating func updateParameters(gamma: Float, k: Float) {
        // 1. Enregistrer delta et pente avant de modifier la courbe.
        let deltaT = elapsedSec
        let slope = getSlope(deltaT: deltaT)
        let delta = getDelta(deltaT: deltaT)
        // 2. Mise à jour des paramètres de la courbe
        setLambdaBetaType(gamma: gamma, k: k)
        // 3. Réévaluer a/b pour nouveau lambda/beta
        setAB(delta: delta, slope: slope)
        // 4. Reset time
        setTime = RenderingChrono.elapsedMS32
    }
    mutating func setLambdaBetaType(gamma: Float, k: Float) {
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
    mutating func setAB(delta: Float, slope: Float) {
        switch type {
        case .oscAmorti:
            A = delta
            B = (slope + lambda * A) / beta
        case .amortiCrit:
            A = delta
            B = slope + lambda * A
        case .surAmorti:
            A = (beta * delta + slope) / (beta - lambda)
            B = delta - A
        case .static_:
            A = 0; B = 0
        }
    }
    func getSlope(deltaT: Float) -> Float {
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
    func getDelta(deltaT: Float) -> Float {
        switch type {
        case .oscAmorti:
            return expf(-lambda * deltaT) * (A * cosf(beta * deltaT) + B * sinf(beta * deltaT))
        case .amortiCrit:
            return (A + B * deltaT) * expf(-lambda * deltaT)
        case .surAmorti:
            return A * expf(-lambda * deltaT) + B * expf(-beta * deltaT)
        case .static_:
            return 0
        }
    }
}

struct SmoothPos : SmoothDimension, CurveInfo {
    private(set) var realPos: Float
    var defPos: Float
    var pos: Float {
        get {
            return getDelta(deltaT: elapsedSec) + realPos
        }
        set(newPos) {
            set(newPos, false, false)
        }
    }
    var speed: Float {
        get { return getSlope(deltaT: elapsedSec) }
    }
     
    init(_ posInit: Float, _ lambda: Float) {
        defPos = posInit
        realPos = posInit
        setTime = RenderingChrono.elapsedMS32
        setLambdaBetaType(gamma: 2 * lambda, k: lambda * lambda)
    }
    init(_ posInit: Float) {
        defPos = posInit
        realPos = posInit
        setTime = RenderingChrono.elapsedMS32
    }
    
    mutating func set(_ newPos: Float, _ fix: Bool = true, _ setAsDef: Bool = true) {
        if setAsDef {
            defPos = newPos
        }
        if fix {
            A = 0; B = 0
        } else {
            let deltaT = elapsedSec
            setAB(delta: getDelta(deltaT: deltaT) + realPos - newPos, slope: getSlope(deltaT: deltaT))
            setTime = RenderingChrono.elapsedMS32
        }
        realPos = newPos
    }
    
    mutating func updateCurve(lambda: Float) {
        updateParameters(gamma: 2 * lambda, k: lambda * lambda)
    }
    mutating func updateCurve(gamma: Float, k: Float) {
        updateParameters(gamma: gamma, k: k)
    }
    
    /** Changement de référentiel quelconques (avec positions et scales absolues). */
    mutating func newReferential(pos: Float, destPos: Float,
                       posScale: Float, destScale: Float) {
        realPos = (pos - destPos) / destScale
        A = A * posScale / destScale
        B = B * posScale / destScale
    }
    mutating func newReferentialAsDelta(posScale: Float, destScale: Float) {
        realPos = realPos * posScale / destScale
        A = A * posScale / destScale
        B = B * posScale / destScale
    }
    /** Simple changement de référentiel vers le haut.
     *  Se place dans le référentiel du grand-parent. */
    mutating func referentialUp(oldParentPos: Float, oldParentScaling: Float) {
        realPos = realPos * oldParentScaling + oldParentPos
        A *= oldParentScaling
        B *= oldParentScaling
    }
    mutating func referentialUpAsDelta(oldParentScaling: Float) {
        realPos *= oldParentScaling
        A *= oldParentScaling
        B *= oldParentScaling
    }
    /** Simple changement de référentiel vers le bas.
     *  Se place dans le reférentiel d'un frère qui devient parent. */
    mutating func referentialDown(newParentPos: Float, newParentScaling: Float) {
        realPos = (realPos - newParentPos) / newParentScaling
        A /= newParentScaling
        B /= newParentScaling
    }
    mutating func referentialDownAsDelta(newParentScaling: Float) {
        realPos /= newParentScaling
        A /= newParentScaling
        B /= newParentScaling
    }
    
    fileprivate var A: Float = 0
    fileprivate var B: Float = 0
    fileprivate var lambda: Float = 0
    fileprivate var beta: Float = 0
    fileprivate var type: SmDimType = .static_
    fileprivate var setTime: UInt32
}

struct SmoothAngle : SmoothDimension, CurveInfo {
    private(set) var realPos: Float
    var defPos: Float
    var pos: Float {
        get {
            return getDelta(deltaT: elapsedSec) + realPos
        }
        set(newPos) {
            set(newPos, false, false)
        }
    }
    var speed: Float {
        get { return getSlope(deltaT: elapsedSec) }
    }
    
    init(_ posInit: Float, _ lambda: Float) {
        defPos = posInit.toNormalizedAngle()
        realPos = defPos
        setTime = RenderingChrono.elapsedMS32
        setLambdaBetaType(gamma: 2 * lambda, k: lambda * lambda)
    }
    init(_ posInit: Float) {
        defPos = posInit.toNormalizedAngle()
        realPos = defPos
        setTime = RenderingChrono.elapsedMS32
    }
    
    mutating func set(_ newPos: Float, _ fix: Bool, _ setAsDef: Bool) {
        if setAsDef {
            defPos = newPos.toNormalizedAngle()
        }
        if fix {
            A = 0; B = 0
        } else {
            let deltaT = elapsedSec
            setAB(delta: (getDelta(deltaT: deltaT) + realPos - newPos).toNormalizedAngle(), slope: getSlope(deltaT: deltaT))
            setTime = RenderingChrono.elapsedMS32
        }
        realPos = newPos.toNormalizedAngle()
    }
	
	mutating func updateCurve(lambda: Float) {
		updateParameters(gamma: 2 * lambda, k: lambda * lambda)
	}
	mutating func updateCurve(gamma: Float, k: Float) {
		updateParameters(gamma: gamma, k: k)
	}
    
    fileprivate var A: Float = 0
    fileprivate var B: Float = 0
    fileprivate var lambda: Float = 0
    fileprivate var beta: Float = 0
    fileprivate var type: SmDimType = .static_
    fileprivate var setTime: UInt32
}

struct SmoothAngleWithDrift : SmoothDimension, CurveInfo {
    private(set) var drift: Float = 0
    private(set) var realPos: Float
    var defPos: Float
    var pos: Float {
        get {
            let deltaT = elapsedSec
            return getDelta(deltaT: deltaT) + drift * deltaT + realPos
        }
        set(newPos) {
            set(newPos, false, false)
        }
    }
    var speed: Float {
        get { return getSlope(deltaT: elapsedSec) + drift }
    }
    
    init(_ posInit: Float, _ lambda: Float) {
        defPos = posInit.toNormalizedAngle()
        realPos = defPos
        setTime = RenderingChrono.elapsedMS32
        setLambdaBetaType(gamma: 2 * lambda, k: lambda * lambda)
    }
    init(_ posInit: Float) {
        defPos = posInit.toNormalizedAngle()
        realPos = defPos
        setTime = RenderingChrono.elapsedMS32
    }
    
    mutating func set(_ newPos: Float, _ fix: Bool, _ setAsDef: Bool) {
        if setAsDef {
            defPos = newPos.toNormalizedAngle()
        }
        if fix {
            A = 0; B = 0
        } else {
            let deltaT = elapsedSec
            setAB(
                delta: (getDelta(deltaT: deltaT) + drift * deltaT + realPos - newPos).toNormalizedAngle(),
                slope: getSlope(deltaT: deltaT) + drift)
            setTime = RenderingChrono.elapsedMS32
        }
        realPos = newPos.toNormalizedAngle()
        drift = 0
    }
    mutating func set(_ newPos: Float, newDrift: Float) {
        let deltaT = elapsedSec
            setAB(
                delta: (getDelta(deltaT: deltaT) + drift * deltaT + realPos - newPos).toNormalizedAngle(),
                slope: getSlope(deltaT: deltaT) + drift - newDrift)
            setTime = RenderingChrono.elapsedMS32
            realPos = newPos.toNormalizedAngle()
            drift = newDrift
    }
    
    fileprivate var A: Float = 0
    fileprivate var B: Float = 0
    fileprivate var lambda: Float = 0
    fileprivate var beta: Float = 0
    fileprivate var type: SmDimType = .static_
    fileprivate var setTime: UInt32
}
