//
//  coqSound.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2018-10-30.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import AVFoundation

enum SoundManager {
    static private(set) var isMute: Bool = false
    
    static func loadSounds() {
        for soundName in SoundEnum.allCases {
            if let url = Bundle.main.url(forResource: "\(soundName)", withExtension: "wav", subdirectory: "Sounds") {
                do {
                    let sound = try AVAudioPlayer(contentsOf: url)
                    soundsList.append(sound)
                } catch {
                    printerror("Ne peut charger \(soundName)")
                }
            } else {
                printerror("Pas de sons \(soundName)")
            }
            
        }
    }
    
    static func toggleMute() {
        isMute = !isMute
    }
    
    static func play(sound: SoundEnum, pitch: Int = 0, volume: Float = 1) {
        if isMute {return}
        if sound.rawValue >= soundsList.count { printerror("Son \(sound) pas loadé."); return }
        soundsList[sound.rawValue]?.rate = powf(2, Float(pitch)/12)
        soundsList[sound.rawValue]?.volume = volume
        soundsList[sound.rawValue]?.enableRate = true
        soundsList[sound.rawValue]?.prepareToPlay()
        soundsList[sound.rawValue]?.play()
    }
    
    private static var soundsList: [AVAudioPlayer?] = []
}
