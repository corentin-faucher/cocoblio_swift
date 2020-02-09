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

    func applicationDidResignActive(_ notification: Notification) {
        metalView.pause()
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        metalView.touch()
    }
}

