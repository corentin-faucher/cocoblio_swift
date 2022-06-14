//
//  Sound.swift
//  MasaKiokuGameOSX
//
//  Created by Corentin Faucher on 2020-02-05.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import AVFoundation
//import AppKit

enum Sound : String, CaseIterable {
    case arpeggio
    case bye_bye
    case duck_error
    case fireworks1
    
    
    func play(pitch: Int = 0, volume: Float = 1) {
        guard Sound.engine != nil, !Sound.isMute else { return }
        guard let buffer = Sound.soundToBuffer[self] else {printerror("Buffer not init."); return }
        // Trouver un player disponible...
        var bestIndex: Int = 0
        var bestRemaining: Int64 = 20000
        for (index, expiredTime) in Sound.expiredTimes.enumerated() {
            let remainingTime = expiredTime - AppChrono.elapsedMS
            // Ok, trouvé un fini.
            if remainingTime <= 0 {
                bestIndex = index
                break
            }
            // Sinon, on enregistre le meilleur jusqu'à présent.
            if remainingTime < bestRemaining {
                bestRemaining = remainingTime
                bestIndex = index
            }
        }
        // Setter l'audio player et pitch control à utiliser.
        guard let audioPlayer = Sound.audioPlayers[safe: bestIndex] else { printerror("audio players not init."); return}
        guard let pitchControl = Sound.pitchControls[safe: bestIndex] else { printerror("Pitch control not init."); return}
        
        // Mise à jour du expiredTime (en ms)
        let durationSec = Double(buffer.frameLength) / buffer.format.sampleRate
        Sound.expiredTimes[bestIndex] = AppChrono.elapsedMS + Int64(durationSec * 1000)
        
        // Préparation du player et pitchControl
        if audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        pitchControl.pitch = Float(pitch) * 100
        audioPlayer.volume = volume
        audioPlayer.scheduleBuffer(buffer, completionHandler: nil)
        
//        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { (_) in
//            Sound.stopAudioPlayer(id: usedIndex)
//        }
        
        audioPlayer.play()
    }
    
    
    /*-- Static --*/
    
    private func createBuffer(expectedFormat: AVAudioFormat?) -> AVAudioPCMBuffer? {
        // 1. Loader le wav.
        guard let url = Bundle.main.url(forResource: rawValue, withExtension: "wav", subdirectory: "wavs") else {
            printerror("No url for \(self)."); return nil
        }
        guard let file = try? AVAudioFile(forReading: url) else {printerror("Can't load file for \(self)."); return nil}
        // 2. En faire un audio buffer.
        let count = AVAudioFrameCount(file.length)
        let format = file.processingFormat
        if let theExpFormat = expectedFormat, format != theExpFormat {
            printerror("Not the same format.")
            return nil
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else {
            printerror("Can't init buffer for \(self)."); return nil
        }
        do {
            try file.read(into: buffer, frameCount: count)
        } catch {
            printerror(error.localizedDescription)
            return nil
        }
        return buffer
    }
    
    static func resume() {
        // 1. Init
        guard engine == nil else {printwarning("Sound already init."); return}
        let engine = AVAudioEngine()
        Sound.engine = engine
        
        // 2. Charger les buffers
        var expectedFormat: AVAudioFormat? = nil
        for sound in allCases {
            guard let buffer = sound.createBuffer(expectedFormat: expectedFormat) else {
                printerror("Cannot create buffer for \(sound).")
                continue
            }
            if expectedFormat == nil {
                expectedFormat = buffer.format
            }
            soundToBuffer[sound] = buffer
        }
        guard let format = expectedFormat else {printerror("No format from buffer?"); return}
        
        // 3. Attach/connect 5 AudioPlayers with their PitchControler (On peut jouer jusqu'à 5 sons en même temps...)
        for _ in 0..<Sound.numberOfPlayers {
            let audioPlayer = AVAudioPlayerNode()
            let pitchControler = AVAudioUnitTimePitch()
            expiredTimes.append(AppChrono.elapsedMS)
            audioPlayers.append(audioPlayer)
            pitchControls.append(pitchControler)
            engine.attach(audioPlayer)
            engine.attach(pitchControler)
            engine.connect(audioPlayer, to: pitchControler, format: format)
            engine.connect(pitchControler, to: engine.mainMixerNode, format: format)
        }
        
        // 4. Start sound engine
        engine.prepare()
        do {
            try engine.start()
        } catch {
            printerror(error.localizedDescription)
        }
    }
    
    static func suspend() {
        guard engine != nil else {printwarning("Sound already cleaned."); return}
        soundToBuffer.removeAll()
        pitchControls.removeAll()
        audioPlayers.removeAll()
        expiredTimes.removeAll()
        engine?.stop()
        engine = nil
    }
    
//    private static func stopAudioPlayer(id: Int) {
//        audioPlayers[safe: id]?.stop()
//    }
    static var isLoaded: Bool {
        return engine != nil
    }
    
    
    /*-- Private stuff... --*/
    static var isMute: Bool = true
    static private let numberOfPlayers: Int = 5
    static private var engine: AVAudioEngine? = nil
    static private var soundToBuffer: [Sound : AVAudioPCMBuffer] = [:]
    static private var pitchControls: [AVAudioUnitTimePitch] = []
    static private var audioPlayers: [AVAudioPlayerNode] = []
    static private var expiredTimes: [Int64] = []
}
