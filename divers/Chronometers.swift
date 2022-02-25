//
//  coqTimer.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-24.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Foundation

fileprivate let sleepTime: Int64 = 16000

// Utilisé pour l'affichage, pas le vrai Chrono
// Incrémenté à chaque frame de 1/f seconde, i.e. ~16 ms.
// (pour avoir des animations plus smooth que si on prend le vrai temps...)
enum GlobalChrono {
    private(set) static var elapsedMS: Int64 = 0
    static var elapsedSec: Float {
        get {
            return Float(elapsedMS)/1000
        }
    }
    static var elapsedMS16: UInt16 {
        return UInt16(truncatingIfNeeded: elapsedMS)
    }
    static var elapsedMS32: UInt32 {
        return UInt32(truncatingIfNeeded: elapsedMS)
    }
    static var isPaused: Bool = false {
        didSet {
            if !isPaused {
                touchTime = elapsedMS
            }
        }
    }
    
    static var shouldSleep: Bool {
        return elapsedMS - touchTime > sleepTime
    }
    
    static func update(frequency: Int) {
        guard !isPaused else { return }
        let deltaT = Int64(1000/Float(frequency))
        elapsedMS += deltaT
    }
    
    // Membres privés
    private static var touchTime: Int64 = 0
}

// Vrai temps de référence, basé sur l'horloge interne.
enum RealTime {
    static var isPaused: Bool = false {
        didSet {
            guard isPaused != oldValue else { return }
            time = systemTime - time
        }
    }
    static var elapsedMS: Int64 {
        return isPaused ? time : (systemTime - time)
    }
    
    private static var time: Int64 = systemTime
    private static var systemTime: Int64 {
        return Int64(Date().timeIntervalSinceReferenceDate * 1000)
    }
}



struct Chrono {
    init() {
        time = 0
        isActive = false
    }
    mutating func start() {
        time = GlobalChrono.elapsedMS
        isActive = true
    }
    mutating func stop() {
        isActive = false
        time = 0
    }
    mutating func pause() {
        time = elapsedMS64
        isActive = false
    }
    mutating func unpause() {
        time = startTimeMS
        isActive = true
    }
    /// Le chronomètre est activé.
    private(set) var isActive: Bool
    /// Le temps écoulé depuis "start()" en millisec.
    var elapsedMS64: Int64 {
        return isActive ? (GlobalChrono.elapsedMS - time) : time
    }
	var elapsedMS32: Int32 {
		return Int32(elapsedMS64)
	}
    /// Le temps écoulé depuis "start()" en secondes.
    var elapsedSec: Float {
        return Float(elapsedMS64) / 1000
    }
    /// Le temps global où le chrono a commencé (en millisec).
    var startTimeMS: Int64 {
        return isActive ? time : GlobalChrono.elapsedMS - time;
    }
    
    mutating func add(millisec: Int64) {
        if isActive {
            time -= millisec
        } else {
            time += millisec
        }
    }
    mutating func add(sec: Float) {
        if sec > 0 {
            add(millisec: Int64(sec*1000))
        }
    }
    mutating func remove(millisec: Int64) {
        if (isActive) { // time est le starting time.
            time = (elapsedMS64 > millisec) ? time + millisec : GlobalChrono.elapsedMS
        } else { // time est le temps écoulé.
            time = (time > millisec) ? time - millisec : 0
        }
    }
    mutating func remove(sec: Float) {
        if sec > 0 {
            remove(millisec: Int64(sec*1000))
        }
    }
    
    // Membres privés
    private var time: Int64
}

struct RealChrono {
    /// Le chronomètre est activé.
    private(set) var isActive: Bool
    
    init() {
        time = 0
        isActive = false
    }
    mutating func start() {
        time = RealTime.elapsedMS
        isActive = true
    }
    mutating func stop() {
        isActive = false
        time = 0
    }
    mutating func pause() {
        time = elapsedMS
        isActive = false
    }
    mutating func unpause() {
        time = startTimeMS
        isActive = true
    }
    
    /// Le temps écoulé depuis "start()" en millisec.
    var elapsedMS: Int64 {
        return isActive ? (RealTime.elapsedMS - time) : time
    }
    var elapsedMS32: Int32 {
        return Int32(elapsedMS)
    }
    /// Le temps écoulé depuis "start()" en secondes.
    var elapsedSec: Float {
        return Float(elapsedMS) / 1000
    }
    /// Le temps global où le chrono a commencé (en millisec).
    var startTimeMS: Int64 {
        return isActive ? time : (RealTime.elapsedMS - time);
    }
    
    
    mutating func add(millisec: Int64) {
        if isActive {
            time -= millisec
        } else {
            time += millisec
        }
    }
    mutating func add(sec: Float) {
        if sec > 0 {
            add(millisec: Int64(sec*1000))
        }
    }
    mutating func remove(millisec: Int64) {
        if (isActive) { // time est le starting time.
            time = (elapsedMS > millisec) ? time + millisec : RealTime.elapsedMS
        } else { // time est le temps écoulé.
            time = (time > millisec) ? time - millisec : 0
        }
    }
    mutating func remove(sec: Float) {
        if sec > 0 {
            remove(millisec: Int64(sec*1000))
        }
    }
    
    // Membres privés
    /// isActive: startTime, notActive: elapsedTime
    private var time: Int64
}

/// Chrono pour debugging... (toujours actif)
struct ChronoChecker {
    init(_ name: String? = nil) {
        time = RealTime.elapsedMS
        count = 0
        str = "🦤 \(name ?? "timer"): "
    }
    mutating func tic(_ message: String? = nil) {
        count += 1
        str += "\(message ?? String(count)) \(elapsedMS), "
    }
    mutating func print() {
        str += "ended \(elapsedMS)."
        Swift.print(str)
    }
    /// Le temps écoulé depuis "start()" en millisec.
    var elapsedMS: Int64 {
        return RealTime.elapsedMS - time
    }
    var elapsedMS32: Int32 {
        return Int32(elapsedMS)
    }
    /// Le temps écoulé depuis "start()" en secondes.
    var elapsedSec: Float {
        return Float(elapsedMS) / 1000
    }
    
    // Membres privés
    /// isActive: startTime, notActive: elapsedTime
    private var time: Int64
    private var str: String
    private var count: Int
}


struct CountDown {
    private(set) var isActive: Bool
    var isRinging: Bool {
        if isActive {
            return ((GlobalChrono.elapsedMS - time) > ringTimeMS)
        } else {
            return (time > ringTimeMS)
        }
    }
    var ringTimeMS: Int64
    var ringTimeSec: Float {
        get {
            return Float(ringTimeMS) / 1000
        }
        set(newRingTimeSec) {
            ringTimeMS = Int64(newRingTimeSec * 1000)
        }
    }
	var elapsedMS64: Int64 {
		return isActive ? (GlobalChrono.elapsedMS - time) : time
	}
	var remainingMS: Int64 {
		let elapsed = elapsedMS64
		if elapsed > ringTimeMS {
			return 0
		} else {
			return ringTimeMS - elapsed
		}
	}
	var remainingSec: Double {
		return Double(remainingMS) / 1000
	}
    
    init(ringMillisec: Int64) {
        isActive = false
        time = 0
        ringTimeMS = ringMillisec
    }
    init(ringSec: Float) {
        isActive = false
        time = 0
        let ringSecPos = max(ringSec, 0)
        ringTimeMS = Int64(ringSecPos*1000)
    }
    
    mutating func start() {
        time = GlobalChrono.elapsedMS
        isActive = true
    }
    mutating func stop() {
        isActive = false
        time = 0
    }
    
    // Membres privés
    private var time: Int64
}


struct RealCountDown {
    private(set) var isActive: Bool
    var isRinging: Bool {
        if isActive {
            return ((RealTime.elapsedMS - time) > ringTimeMS)
        } else {
            return (time > ringTimeMS)
        }
    }
    var ringTimeMS: Int64
    var ringTimeSec: Float {
        get {
            return Float(ringTimeMS) / 1000
        }
        set(newRingTimeSec) {
            ringTimeMS = Int64(newRingTimeSec * 1000)
        }
    }
    var elapsedMS64: Int64 {
        return isActive ? (RealTime.elapsedMS - time) : time
    }
    var remainingMS: Int64 {
        let elapsed = elapsedMS64
        if elapsed > ringTimeMS {
            return 0
        } else {
            return ringTimeMS - elapsed
        }
    }
    var remainingSec: Double {
        return Double(remainingMS) / 1000
    }
    
    init(ringMillisec: Int64) {
        isActive = false
        time = 0
        ringTimeMS = ringMillisec
    }
    init(ringSec: Float) {
        isActive = false
        time = 0
        let ringSecPos = max(ringSec, 0)
        ringTimeMS = Int64(ringSecPos*1000)
    }
    
    mutating func start() {
        time = RealTime.elapsedMS
        isActive = true
    }
    mutating func stop() {
        isActive = false
        time = 0
    }
    
    // Membres privés
    private var time: Int64
}


struct SmallChrono {
    var elapsedMS16: UInt16 {
        return GlobalChrono.elapsedMS16 &- startTime
    }
    var elapsedSec: Float {
        return Float(GlobalChrono.elapsedMS16 &- startTime)/1000
    }
    
    mutating func start() {
        startTime = GlobalChrono.elapsedMS16
    }
    mutating func setElapsedTo(newTimeMS: UInt16) {
        startTime = GlobalChrono.elapsedMS16 &- newTimeMS
    }
    
    // Membre privé
    private var startTime: UInt16 = 0
}
