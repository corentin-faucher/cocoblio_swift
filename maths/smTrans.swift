//
//  smTrans.swift
//  MasaKiokuGameOSX
//
//  Created by Corentin Faucher on 2018-11-21.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Foundation

struct SmTrans {
    mutating func setAndGet(isOn: Bool) -> Float {
        set(isOn: isOn)
        return privateGet()
    }
    
    mutating func get() -> Float {
        switch transState {
        case SmTrans.goingDown:
            if chrono.elapsedMS16 > transTime {
                transState = SmTrans.isDown
            }
        case SmTrans.goingUp:
            if chrono.elapsedMS16 > transTime {
                transState = SmTrans.isUp
            }
        default: break
        }
        return privateGet()
    }
    
    mutating func set(isOn: Bool) {
        if isOn {
            switch transState {
            case SmTrans.isDown:
                if extraState & SmTrans.hard != 0 {
                    transState = SmTrans.isUp
                } else {
                    chrono.start()
                    transState = SmTrans.goingUp
                }
            case SmTrans.goingUp:
                if chrono.elapsedMS16 > transTime {
                    transState = SmTrans.isUp
                }
            case SmTrans.goingDown:
                let time = chrono.elapsedMS16
                if time < transTime {
                    chrono.setElapsedTo(newTimeMS: transTime - time)
                } else {
                    chrono.start()
                }
                transState = SmTrans.goingUp
            default: break
            }
        } else {
            switch transState {
            case SmTrans.isUp:
                if extraState & SmTrans.hard != 0 {
                    transState = SmTrans.isDown
                } else {
                    chrono.start()
                    transState = SmTrans.goingDown
                }
            case SmTrans.goingDown:
                if chrono.elapsedMS16 > transTime {
                    transState = SmTrans.isDown
                }
            case SmTrans.goingUp:
                let time = chrono.elapsedMS16
                if time < transTime {
                    chrono.setElapsedTo(newTimeMS: transTime - time)
                } else {
                    chrono.start()
                }
                transState = SmTrans.goingDown
            default: break
            }
        }
    }
    
    mutating func hardSet(isOn: Bool) {
        transState = isOn ? SmTrans.isUp : SmTrans.isDown
    }
    mutating func setOptions(isHard: Bool, isPoping: Bool) {
        if isHard {
            extraState |= SmTrans.hard
        } else {
            extraState &= ~SmTrans.hard
        }
        if isPoping {
            extraState |= SmTrans.poping
        } else {
            extraState &= ~SmTrans.poping
        }
    }
    var isActive: Bool {
        return transState != SmTrans.isDown
    }
    
    
    
    
    // Private stuff...
    private func privateGet() -> Float {
        func pipPop() -> Float {
            let ratio: Float = Float(chrono.elapsedMS16) / Float(transTime)
            return  SmTrans.a + SmTrans.b * cosf(.pi * ratio) +
                (0.5 - SmTrans.a) * cosf(2 * .pi * ratio) +
                (-0.5 - SmTrans.b) * cosf(3 * .pi * ratio)
        }
        func smooth() -> Float {
            let ratio: Float = Float(chrono.elapsedMS16) / Float(transTime)
            return (1 - cosf(.pi * ratio))/2
        }
        func smoothDown() -> Float {
            let ratio: Float = Float(chrono.elapsedMS16) / Float(transTime)
            return (1 + cosf(.pi * ratio))/2
        }
        
        switch transState {
        case SmTrans.isDown: return 0
        case SmTrans.goingUp: return (extraState & SmTrans.semi != 0 ? SmTrans.semiFact : 1) *
            (extraState & SmTrans.poping != 0 ? pipPop() : smooth())
        case SmTrans.goingDown: return (extraState & SmTrans.semi != 0 ? SmTrans.semiFact : 1) * smoothDown()
        default: return extraState & SmTrans.semi != 0 ? SmTrans.semiFact : 1
        }
    }
    
    
    //-- Data (private) --
    private var chrono = SmallChrono()
    private var transTime: UInt16 = SmTrans.defTransTime
    private var transState: UInt8 = 0
    private var extraState: UInt8 = 0
    
    
    
    // Enum et static
    static func updateParameters(newPopFactor: Float?, newSemiFactor: Float?, newTransTime: UInt16?) {
		if let pf = newPopFactor {
			a = 0.75 + pf * 0.2
			b = -0.43 + pf * 0.43
		}
		if let sf = newSemiFactor {
			semiFact = sf
		}
		if let tt = newTransTime {
			defTransTime = tt
		}
    }
    private enum TransEnum {
        case isDown
        case isUp
        case goingUp
        case goingDown
    }
    //-- States
    private static let poping: UInt8 = 1
    private static let hard: UInt8 = 2
    private static let semi: UInt8 = 4
    
    private static let isDown: UInt8 = 0
    private static let goingUp: UInt8 = 1
    private static let goingDown: UInt8 = 2
    private static let isUp: UInt8 = 3
    
    //-- Parametres static
    private static var semiFact: Float = 0.4
    private static var defTransTime: UInt16 = 500
	private static var a: Float = 0.75 + (0.2) * 0.2  // (pop factor est de 0.2 par défaut)
	private static var b: Float = -0.43 + (0.2) * 0.43
}
