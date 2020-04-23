//
//  EventsHandler.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-04-07.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation
#if os(OSX)
import AppKit
import Carbon
import Carbon.HIToolbox
#endif


protocol EventsHandler {
	func singleTap(pos: Vector2)
	func initTouchDrag()
	func touchDrag(posNow: Vector2)
	func letTouchDrag(vit: Vector2)
	
	func keyDown(key: KeyboardKey)
	func keyUp(key: KeyboardKey)
	func modifiersChangedTo(_ newModifiers: UInt)
	
	func appStart()
	func configurationChanged()
	func appPaused()
	
	func willDrawFrame()
}

protocol KeyboardKey {
	var keycode: UInt16 { get }
	var keymod: UInt { get }
	var isVirtual: Bool { get }
}

struct KeyData : KeyboardKey {
	var keycode: UInt16
	var keymod: UInt
	var isVirtual: Bool
}

enum Keycode {
	// Touches modifier
	static let command: UInt16 = 0x37
	static let shift: UInt16 = 0x38
	static let capsLock: UInt16 = 0x39
	static let option: UInt16 = 0x3A
	static let control: UInt16 = 0x3B
	static let rightCommand: UInt16 = 0x36
	static let rightShift: UInt16 = 0x3C
	static let rightOption: UInt16 = 0x3D
	static let rightControl: UInt16 = 0x3E
	// Touche "importantes"
	static let return_: UInt16 = 0x24
	static let keypadEnter: UInt16 = 0x4C
	static let tab: UInt16 = 0x30
	static let space: UInt16 = 0x31
	static let delete: UInt16 = 0x33
	static let forwardDelete: UInt16 = 0x75
	static let escape: UInt16 = 0x35
	// Touches de directions
	static let leftArrow : UInt16 = 0x7B
	static let rightArrow: UInt16 = 0x7C
	static let downArrow: UInt16 = 0x7D
	static let upArrow: UInt16 = 0x7E
	// Touches spéciales ANSI, ISO, JIS
	static let ANSI_Backslash: UInt16 = 0x2A
	static let ANSI_Grave = 0x32
	static let ISO_section: UInt16 = 0x0A
	static let JIS_Yen: UInt16 = 0x5D
	static let JIS_Underscore: UInt16 = 0x5E
	static let JIS_KeypadComma: UInt16 = 0x5F
	static let JIS_Eisu: UInt16 = 0x66
	static let JIS_Kana: UInt16 = 0x68
	// Dummy "empty" (touche "vide" ne faisant rien)
	static let empty: UInt16 = 0xFF
}

enum Modifier {
	static let command: UInt = 1 << 8
	static let shift: UInt = 1 << 9
	static let capsLock: UInt = 1 << 10
	static let option: UInt = 1 << 11
	static let control: UInt = 1 << 12
	
	static let shiftOrOption = shift | option
}
