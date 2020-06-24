//
//  coqTimer.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-24.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Foundation

struct GlobalChrono {
    // Getters
    /// Active/désactive le chrono du temps écoulé.
    /// Setter à false a pour effet de "toucher" le chrono (évite de s'endormir).
    static var isPaused: Bool {
        set {
            if !newValue { // isPaused == false -> isActive == true
                isActive = true
                touchTime = startingTime + elapsedMS
                touchElapsed = 0
                if !isActive {justUnpause = true}
            } else {
                isActive = false
            }
        }
        get { return !isActive }
    }
    static var shouldSleep: Bool {
        return touchElapsed > 15000
    }
    private(set) static var elapsedMS: Int64 = 0
    static var elapsedSec: Float {
        return Float(elapsedMS)/1000
    }
    static var elapsedMS16: UInt16 {
        return UInt16(truncatingIfNeeded: elapsedMS)
    }
    static var elapsedMS32: UInt32 {
        return UInt32(truncatingIfNeeded: elapsedMS)
    }
    
    static func update() {
        if startingTime == 0 { // Pas init...
            startingTime = systemTime
            touchTime = startingTime
            isActive = true
        }
        if justUnpause {
            startingTime = systemTime - elapsedMS
            touchTime = systemTime - touchElapsed
            justUnpause = false
            return
        }
        if isActive {
            // Cas patologique où il n'y a pas eu de mise à jour depuis longtemps...
            if systemTime - startingTime - elapsedMS > 500 {
                startingTime = systemTime - elapsedMS - 500 // Interval plafonne à 500
                touchTime = systemTime - touchElapsed - 500
            }
            elapsedMS = systemTime - startingTime
            touchElapsed = systemTime - touchTime
        }
    }
    
    // Membres privés
    private static var isActive: Bool = false
    private static var startingTime: Int64 = 0
    private static var touchTime: Int64 = 0
    private static var touchElapsed: Int64 = 0
    private static var justUnpause: Bool = false
    private static var systemTime: Int64 {
        return Int64(Date().timeIntervalSinceReferenceDate * 1000)
    }
}

struct Chrono {
    /// Le chronomètre est activé.
    private(set) var isActive: Bool
    /// Le temps écoulé depuis "start()" en millisec.
    var elapsedMS64: Int64 {
        return isActive ? (GlobalChrono.elapsedMS - time) : time
    }
	var elapsedMS32: Int32 {
		return Int32(isActive ? (GlobalChrono.elapsedMS - time) : time)
	}
    /// Le temps écoulé depuis "start()" en secondes.
    var elsapsedSec: Float {
        return Float(elapsedMS64) / 1000
    }
    /// Le temps global où le chrono a commencé (en millisec).
    var startTimeMS: Int64 {
        return isActive ? time : GlobalChrono.elapsedMS - time;
    }
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
    /// isActive: startTime, notActive: elapsedTime
    private var time: Int64
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
