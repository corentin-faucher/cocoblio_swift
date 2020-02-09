//
//  coqSound.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2018-10-30.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import AVFoundation

enum SoundManager {
    static var isMute = false
    
    static func initWavSound(wavID: String) {
        guard soundIDtoAudioPlayer[wavID] == nil else {
            printerror("Texture du png \(wavID) déjà init.")
            return
        }
        guard let url = Bundle.main.url(
            forResource: "\(wavID)", withExtension: "wav", subdirectory: "wavs") else {
            printerror("Wav file \(wavID) not found.")
            return
        }
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            soundIDtoAudioPlayer[wavID] = audioPlayer
        } catch {
            printerror("Ne peut charger \(wavID).")
        }
    }
    static func getWavSound(wavID: String) -> AVAudioPlayer? {
        guard let audioPlayer = soundIDtoAudioPlayer[wavID] else {
            printerror("Son du wav \(wavID) pas encore init.")
            return nil
        }
        return audioPlayer
    }
    static func playWavSound(wavID: String, pitch: Int = 0, volume: Float = 1) {
        guard let audioPlayer = soundIDtoAudioPlayer[wavID] else {
            printerror("Son du wav \(wavID) pas encore init.")
            return
        }
        if SoundManager.isMute {return}
        audioPlayer.rate = powf(2, Float(pitch)/12)
        audioPlayer.volume = volume
        audioPlayer.enableRate = true
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }
    static private var soundIDtoAudioPlayer: [String : AVAudioPlayer] = [:]
}


extension AVAudioPlayer {
    func play(pitch: Int, volume: Float = 1) {
        if SoundManager.isMute {return}
        rate = powf(2, Float(pitch)/12)
        self.volume = volume
        enableRate = true
        prepareToPlay()
        play()
    }
}
