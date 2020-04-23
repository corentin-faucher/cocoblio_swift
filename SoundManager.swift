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
	
	@discardableResult
	static func preloadSound(wavId: String) -> AVAudioPlayer? {
		guard let url = Bundle.main.url(forResource: wavId, withExtension: "wav", subdirectory: "wavs") else {
			printerror("No url for \(wavId).")
			return nil
		}
		guard let ap = try? AVAudioPlayer(contentsOf: url) else {
			printerror("Cannot load \(wavId).")
			return nil
		}
		soundIDtoAudioPlayer[wavId] = ap
		return ap
	}
    static func playWavSound(wavId: String, pitch: Int = 0, volume: Float = 1) {
		guard !isMute else {return}
		DispatchQueue.global().async {
			let audioPlayer: AVAudioPlayer
			if let ap = soundIDtoAudioPlayer[wavId] {
				audioPlayer = ap
			} else {
				guard let ap = preloadSound(wavId: wavId) else { return }
				printwarning("\(wavId) not preloaded.")
				audioPlayer = ap
			}
			audioPlayer.rate = powf(2, Float(pitch)/12)
			audioPlayer.volume = volume
			audioPlayer.enableRate = true
			audioPlayer.prepareToPlay()

			audioPlayer.play()
		}
		
		
    }
    static private var soundIDtoAudioPlayer: [String : AVAudioPlayer] = [:]
}
