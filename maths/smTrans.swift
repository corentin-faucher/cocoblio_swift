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
        switch transEnum {
        case .goingDown:
            if chrono.elapsedMS16 > transTime {
                transEnum = .isDown
            }
        case .goingUp:
            if chrono.elapsedMS16 > transTime {
                transEnum = .isUp
            }
        default: break
        }
        return privateGet()
    }
    
    mutating func set(isOn: Bool) {
        if isOn {
            switch transEnum {
            case .isDown:
                if extraState.contains(.hard) {
                    transEnum = .isUp
                } else {
                    chrono.start()
                    transEnum = .goingUp
                }
            case .goingUp:
                if chrono.elapsedMS16 > transTime {
                    transEnum = .isUp
                }
            case .goingDown:
                let time = chrono.elapsedMS16
                if time < transTime {
                    chrono.setElapsedTo(newTimeMS: transTime - time)
                } else {
                    chrono.start()
                }
                transEnum = .goingUp
            default: break
            }
        } else {
            switch transEnum {
            case .isUp:
                if extraState.contains(.hard) {
                    transEnum = .isDown
                } else {
                    chrono.start()
                    transEnum = .goingDown
                }
            case .goingDown:
                if chrono.elapsedMS16 > transTime {
                    transEnum = .isDown
                }
            case .goingUp:
                let time = chrono.elapsedMS16
                if time < transTime {
                    chrono.setElapsedTo(newTimeMS: transTime - time)
                } else {
                    chrono.start()
                }
                transEnum = .goingDown
            default: break
            }
        }
    }
    
    mutating func hardSet(isOn: Bool) {
        transEnum = isOn ? .isUp : .isDown
    }
    mutating func setOptions(isHard: Bool, isPoping: Bool) {
        if isHard {
            extraState.formUnion(.hard)
        } else {
            extraState.subtract(.hard)
        }
        if isPoping {
            extraState.formUnion(.poping)
        } else {
            extraState.subtract(.poping)
        }
    }
    var isActive: Bool {
        return transEnum != .isDown
    }
    
    var extraState = ExtraState()
    struct ExtraState: OptionSet {
        let rawValue: UInt8
        static let poping = ExtraState(rawValue: 1<<0)
        static let hard = ExtraState(rawValue: 1<<1)
        static let semi = ExtraState(rawValue: 1<<2)
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
        
        switch transEnum {
        case .isDown: return 0
        case .isUp: return extraState.contains(.semi) ? SmTrans.semiFact : 1
        case .goingUp: return (extraState.contains(.semi) ? SmTrans.semiFact : 1) *
            (extraState.contains(.poping) ? pipPop() : smooth())
        case .goingDown: return (extraState.contains(.semi) ? SmTrans.semiFact : 1) * smoothDown()
        }
    }
    
    private var chrono = SmallChrono()
    private var transEnum = TransEnum.isDown
    private var transTime: UInt16 = SmTrans.defTransTime
    
    // Enum et static
    static func updateParameters(newPopFactor: Float, newSemiFactor: Float, newTransTime: UInt16) {
        popFact = newPopFactor
        semiFact = newSemiFactor
        defTransTime = newTransTime
        a = 0.75 + popFact * 0.2
        b = -0.43 + popFact * 0.43
    }
    private enum TransEnum {
        case isDown
        case isUp
        case goingUp
        case goingDown
    }
    private static var popFact: Float = 0.2
    private static var semiFact: Float = 0.4
    private static var defTransTime: UInt16 = 500
    private static var a: Float = 0.75 + popFact * 0.2
    private static var b: Float = -0.43 + popFact * 0.43
}
