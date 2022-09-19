//
//  coqTimer.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-24.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Foundation

fileprivate let sleepTime: Int64 = 16000

/** Utilisé pour l'affichage, pas le vrai Chrono
 * Incrémenté à chaque frame de 1/f seconde, i.e. ~16 ms.
 * (pour avoir des animations plus smooth que si on prend le vrai temps...) */
enum RenderingChrono {
    private(set) static var elapsedMS: Int64 = 0
    private static var elapsedAngleMS: Int64 = 0
    static var elapsedSec: Float {
        get {
            return Float(elapsedMS)/1000
        }
    }
    /** Un temps écoulé qui reste toujours entre 0 et 24pi. (Pour les sin/cos) */
    static var elapsedAngle: Float {
        get {
            return Float(elapsedAngleMS)/1000
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
                touchAngleMS = elapsedAngleMS
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
        elapsedAngleMS += deltaT
        if elapsedAngleMS > angleLoopTimeMS {
            elapsedAngleMS -= angleLoopTimeMS
        }
    }
    
    // Membres privés
    private static var touchTime: Int64 = 0
    private static var touchAngleMS: Int64 = 0
    private static let angleLoopTimeMS: Int64 = Int64(24000 * Float.pi)
}

/** Chronometre du temps écoulé depuis l'ouverture de l'app. (Vrais ms/sec écoulées) */
enum AppChrono {
    static var isPaused: Bool = false {
        didSet {
            guard isPaused != oldValue else { return }
            // Mise en pause
            if isPaused {
                startSleepTimeMS = systemTime
            }
            // Sortie de pause
            else {
                lastSleepTimeMS = systemTime - startSleepTimeMS
            }
            // Temps écoulé ou temps de pause...
            time = systemTime - time
        }
    }
    static var elapsedMS: Int64 {
        return isPaused ? time : (systemTime - time)
    }
    // Durée de la dernière pause en secondes.
    static var lastSleepTimeSec: Float {
        return Float(lastSleepTimeMS) / 1000
    }
    /** Si isPause : temps total écoulé sans pause, sinon c'est le systemTime au départ (et sans pause).
     * i.e. isPause == true : time == elapsedTime,  isPause == false : time == systemTime - elapsedTime. */
    private static var time: Int64 = systemTime
    private static var lastSleepTimeMS: Int64 = 0
    private static var startSleepTimeMS: Int64 = 0
    fileprivate static var systemTime: Int64 {
        return Int64(Date().timeIntervalSinceReferenceDate * 1000)
    }
}


/** Un chronomètre (calcul le temps écoulé) basé sur RenderingChrono (pas le vrai temps +1/f à chaque frame). */
struct ChronoR {
    init() {
        time = 0
        isActive = false
    }
    mutating func start() {
        time = RenderingChrono.elapsedMS
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
        return isActive ? (RenderingChrono.elapsedMS - time) : time
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
        return isActive ? time : RenderingChrono.elapsedMS - time;
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
            time = (elapsedMS64 > millisec) ? time + millisec : RenderingChrono.elapsedMS
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

/** Un chronomètre basé sur le AppChrono (temps écoulé sans les "pause" de l'app).
 * N'est pas actif à l'ouverture. */
struct Chrono {
    /// Le chronomètre est activé.
    private(set) var isActive: Bool
    
    init() {
        time = 0
        isActive = false
    }
    mutating func start() {
        time = AppChrono.elapsedMS
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
        return isActive ? (AppChrono.elapsedMS - time) : time
    }
    var elapsedMS32: Int32 {
        return Int32(elapsedMS)
    }
    /// Le temps écoulé depuis "start()" en secondes.
    var elapsedSec: Float {
        return Float(elapsedMS) / 1000
    }
    /// Temps écouler sous la forme hh:mm:ss.
    var elapsedHMS: String {
        let s = elapsedMS / 1000
        let ss = s % 60
        let m = (s / 60) % 60
        let h = s / 3600
        return "\(h):\(String(format: "%02d", m)):\(String(format: "%02d", ss))"
    }
    /// Le temps global où le chrono a commencé (en millisec).
    var startTimeMS: Int64 {
        return isActive ? time : (AppChrono.elapsedMS - time);
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
            time = (elapsedMS > millisec) ? time + millisec : AppChrono.elapsedMS
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

/// Chrono pour debugging... Pour voir le temps pris par divers instructions...
class ChronoChecker {
    init(_ name: String? = nil) {
        time = AppChrono.elapsedMS
        count = 0
        str = "🦤 \(name ?? "timer"): "
    }
    func tic(_ message: String? = nil) {
        count += 1
        str += "\(message ?? String(count)) \(elapsedMS), "
    }
    func print() {
        str += "ended \(elapsedMS)."
        Swift.print(str)
    }
    /// Le temps écoulé depuis "start()" en millisec.
    var elapsedMS: Int64 {
        return AppChrono.elapsedMS - time
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

/** Un compte à rebours basé sur le AppChrono. */
struct Countdown {
    private(set) var isActive: Bool
    var isRinging: Bool {
        if isActive {
            return ((AppChrono.elapsedMS - time) > ringTimeMS)
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
        return isActive ? (AppChrono.elapsedMS - time) : time
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
        time = AppChrono.elapsedMS
        isActive = true
    }
    mutating func stop() {
        isActive = false
        time = 0
    }
    
    // Membres privés
    private var time: Int64
}

/** Un compte à rebours basé sur le SystemTime (vrai temps de l'OS sans tenir compte des pause/resume de l'app).. */
struct CountdownS {
    private(set) var isActive: Bool
    var isRinging: Bool {
        if isActive {
            return ((AppChrono.systemTime - time) > ringTimeMS)
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
        return isActive ? (AppChrono.systemTime - time) : time
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
    init(ringSec: Double) {
        isActive = false
        time = 0
        let ringSecPos = max(ringSec, 0)
        ringTimeMS = Int64(ringSecPos*1000)
    }
    
    mutating func start() {
        time = AppChrono.systemTime
        isActive = true
    }
    mutating func stop() {
        isActive = false
        time = 0
    }
    
    // Membres privés
    private var time: Int64
}

/** Version simplifié de ChronoR. Time sur juste 16 bits -> moins de 32 sec. */
struct SmallChronoR {
    var elapsedMS16: UInt16 {
        return RenderingChrono.elapsedMS16 &- startTime
    }
    var elapsedSec: Float {
        return Float(RenderingChrono.elapsedMS16 &- startTime)/1000
    }
    
    mutating func start() {
        startTime = RenderingChrono.elapsedMS16
    }
    mutating func setElapsedTo(newTimeMS: UInt16) {
        startTime = RenderingChrono.elapsedMS16 &- newTimeMS
    }
    
    // Membre privé
    private var startTime: UInt16 = 0
}
