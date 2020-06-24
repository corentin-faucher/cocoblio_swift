//
//  AppDelegate.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2018-10-30.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var metalView: MetalView!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
	
	func applicationWillResignActive(_ notification: Notification) {
		metalView.isPaused = true
		Sound.suspend()
		Texture.suspend()
	}

    func applicationDidResignActive(_ notification: Notification) {
    }
    func applicationDidBecomeActive(_ notification: Notification) {
		if !Texture.loaded {
			Texture.resume()
			Sound.resume()
		}
        metalView.isPaused = false
    }
}

